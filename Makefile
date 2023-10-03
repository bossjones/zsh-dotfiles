test:
	py.test --tb=short --no-header --showlocals --reruns 6 test_dotfiles.py

test-pdb:
	py.test --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py
