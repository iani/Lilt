// (SC3:) Generated from SynthDesc on: Sat Oct 25 19:11:49 2008

~controlSpecs = [
[ 'k_out', 0, 4095, 'linear', 1, 0 ],
[ 'rate', 0.001, 100, 'linear', 0.0, 1.0 ],
[ 'step', -4.99, 4.99, 'linear', 0.0, 0.01 ],
[ 'lo', -10.0, 10.0, 'linear', 0.0, 0.0 ],
[ 'hi', -10.0, 10.0, 'linear', 0.0, 1.0 ]
];

~start = { Synth("k_stepR", ['k_out', ~k_out, 'rate', ~rate, 'step', ~step, 'lo', ~lo, 'hi', ~hi],
	~target, #[\h, \t, \addBefore, \addAfter, \addReplace][~addAction]) };
