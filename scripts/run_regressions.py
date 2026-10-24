import subprocess
import os
import sys
import glob

env = os.environ.copy()
env['PATH'] = r'P:\iverilog\bin' + os.pathsep + env.get('PATH', '')

tests = [
    ('ALU', ['rtl/core/riscv_pkg.sv', 'rtl/core/alu.sv', 'tb/core/tb_alu.sv']),
    ('RegFile', ['rtl/core/riscv_pkg.sv', 'rtl/core/register_file.sv', 'tb/core/tb_register_file.sv']),
    ('ImmGen', ['rtl/core/riscv_pkg.sv', 'rtl/core/imm_gen.sv', 'tb/core/tb_imm_gen.sv']),
    ('HazardUnit', ['rtl/core/riscv_pkg.sv', 'rtl/core/hazard_unit.sv', 'tb/core/tb_hazard_unit.sv']),
    ('RISCV_Core', ['rtl/core/riscv_pkg.sv', 'rtl/core/*.sv', 'tb/core/tb_riscv_core.sv']),
    ('Accelerator', ['rtl/accelerator/accelerator_pkg.sv', 'rtl/accelerator/*.sv', 'tb/tb_accelerator.sv'])
]

all_pass = True
for name, file_patterns in tests:
    expanded = []
    for pat in file_patterns:
        matches = glob.glob(pat)
        if matches:
            pkgs = [m.replace('\\', '/') for m in matches if 'pkg' in m]
            others = [m.replace('\\', '/') for m in matches if 'pkg' not in m]
            expanded.extend(pkgs + others)
        else:
            expanded.append(pat.replace('\\', '/'))
    
    seen = set()
    flist = []
    for f in expanded:
        if f not in seen:
            seen.add(f)
            flist.append(f)

    vvp_file = f'sim/tb_{name.lower()}.vvp'
    cmd = ['iverilog', '-g2012', '-I', 'rtl', '-I', 'rtl/core', '-I', 'rtl/accelerator', '-o', vvp_file] + flist
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if res.returncode != 0:
        print(f'FAIL to compile {name}:')
        print(res.stderr)
        all_pass = False
        continue
    
    sim = subprocess.run(['vvp', vvp_file], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout_str = sim.stdout.decode('utf-8', errors='replace')
    
    # Check for failure indicators
    fail_indicators = ['error:', 'fail:', 'failed', 'mismatch']
    has_err = False
    for line in stdout_str.splitlines():
        low = line.lower()
        if any(ind in low for ind in ['[fail]', 'mismatch', 'error:']):
            has_err = True
            break

    if has_err or sim.returncode != 0:
        print(f'FAIL: {name}')
        for line in stdout_str.splitlines()[-10:]:
            print('  ', line)
        all_pass = False
    else:
        # Extract summary if available
        summary_lines = [l for l in stdout_str.splitlines() if 'test' in l.lower() or 'pass' in l.lower() or 'all' in l.lower()]
        last_line = summary_lines[-1] if summary_lines else stdout_str.splitlines()[-1] if stdout_str.splitlines() else "Complete"
        print(f'PASS: {name} -> {last_line.strip()}')

if all_pass:
    print('\n=======================================')
    print(' ALL 6 REGRESSION SUITES PASSED (0 ERRORS) ')
    print('=======================================')
