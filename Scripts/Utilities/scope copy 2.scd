/* Redoing stethoscope to add: 
- Always start when the server boots (independently of whether the scope was opened)
- Restart automatically when all synths are stopped by command-. or by rebooting the server

Buffer.alloc(Server.internal, 1024, 1, { "hello".postln });
{ WhiteNoise.ar(0.1) }.play(Server.internal);
{ SinOsc.ar(1024 / 4, 0, 0.1) }.play(Server.internal);

*/

var script, server, window, scope_view, on_off_button, is_on = true;
var bufsize = 2048, buffer, synth; 
var rate = 'audio', max_channels, num_channels = 2, channel_offset = 0;
var makeWindow, alloc_buffer_and_start, start_synth, on_reset;

script = ~script;
server = Server.internal;
max_channels = server.options.numAudioBusChannels;

alloc_buffer_and_start = { // | on_status |
//	['alloc_buffer_and_start - func - on_status, is_on', on_status, is_on].postln;
//	if (on_status == true) { is_on = true};
	Buffer.alloc(server, bufsize, num_channels, { | buf |
		buffer = buf;	// must set buffer here coz it runs immediately
//		start_synth.value;
		if (is_on) { start_synth.value };
		nil;	// needed for alloc method
	});
};

start_synth = {
	["---- this is the goddam start synth thingy. is_on, synth", is_on, synth].postln;
	if (synth.isNil) {
		"starting new synth now!!!!!!!!!!!".postln;
		synth = SynthDef("stethoscope", { | in, switch, bufnum |
			var z;
			z = Select.ar(switch, [In.ar(in, num_channels), K2A.ar(In.kr(in, num_channels))]); 
			ScopeOut.ar(z, bufnum);
		}).play(RootNode(server), [\bufnum, buffer.bufnum, \in, channel_offset, \switch] 
			++ if(rate  === 'audio') { 0 } { 1 },
			\addToTail
		);
		synth.onStart({ { on_off_button.value = 0 }.defer })
			.onEnd({ synth = nil; { if (window.notNil) { on_off_button.value = 1 } }.defer });
		{ scope_view.bufnum = buffer.bufnum; }.defer;
		is_on = true;
	};
};

on_reset = { is_on.if(start_synth) };

~start = {
	if (window.isNil) { makeWindow.value };
	if (server.serverRunning.not) { server.boot };
	script.onBoot(
		alloc_buffer_and_start, 
		server,
		true
	);
	on_reset.onReset(server, true);
	window.onClose = {
		ServerWatcher.for(server).remove(script).remove(on_reset);
		if (server.serverRunning) { if (synth.notNil) {synth.free}; buffer.free; buffer = nil };
		script.stopped;
	};
	window.front;
};

~stop = {
	window.close; window = nil;
};

makeWindow = {
	var bounds, scope_rect, controls_rects;
	window = GUI.window.new("scope",Rect(500, 0, 350, 300)).front;
	bounds = window.view.bounds.insetBy(10, 10);
	#scope_rect, controls_rects = bounds.rows(260);
	scope_view = GUI.scopeView.new(window, scope_rect).resize = 5;	// be elastic
	controls_rects = controls_rects.g_cols(2, 2, 40, 60, 70, 40, 70);
	on_off_button = GUI.button.new(window, controls_rects[0])
		.states_([ [ "on", Color(1.0, 0.0, 0.0, 1.0), Color(1.0, 1.1, 1.0, 1.0) ], 
			[ "off", Color(0.0, 0.0, 0.0, 0.5), Color(0.8, 0.8, 0.8, 1.0) ] ])
		.resize_(7)
		.value_(is_on.not.binaryValue)
		.action_{|v| [start_synth, { { synth.postln.free; is_on = false }.defer }][v.value].value;
		};
	GUI.button.new(window, controls_rects[1])
		.states_([ [ "audio", Color(0.0, 0.0, 0.0, 1.0), Color(1.0, 0.0, 0.0, 1.0) ], 
			[ "control", Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 0.0, 1.0, 1.0) ] ])
		.resize_(7).action_({|v|
			[{	rate = 'audio'; 
				max_channels = server.options.numAudioBusChannels;
			},{ rate = 'control'; 
				max_channels = server.options.numControlBusChannels;
			}][v.value].value;
			if (synth.notNil) { synth.set(\switch, (rate == 'control').binaryValue) } 
		});
	GUI.staticText.new(window, controls_rects[2])
		.string_("num. chan.").align_(\right).resize_(7);
	GUI.numberBox.new(window, controls_rects[3])
		.resize_(7).action_({|v|
			v.value = num_channels = v.value.clip(0, 16);
			if (buffer.notNil) { buffer.free };			
			["the synth before testing it to free it in chan number change", synth].postln;
			if (synth.notNil) {
				synth.free;
				synth onEnd: { synth = nil; alloc_buffer_and_start };
				// "freed synth!".postln; synth = nil;
			};
			["the synth AFTER testing it to free it in chan number change", synth].postln;			
			alloc_buffer_and_start.value;
		}).value_(num_channels);
	GUI.staticText.new(window, controls_rects[4])
		.string_("chan. offset").align_(\right).resize_(7);
	GUI.numberBox.new(window, controls_rects[5])
		.resize_(7).action_({|v| 
			channel_offset = v.value.clip(0, max_channels);
			v.value = channel_offset;
			if (synth.notNil) { synth.set(\in, channel_offset) }
		}).value_(channel_offset);
};

