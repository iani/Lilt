/* Parameter for handling audio buffers in scripts
0508 and later

broken 080517
Replaced by yesterdays version Saturday; May 17, 2008: 10:50 AM
*/

BufParameter : Parameter {
	var buffer, samples;
	init { | argAction |
		super.init(argAction);
		samples = Samples(script.session.server);
		script.hasBufferInput = true;
	}
	buffer_ { | argBuffer |
		if (buffer.notNil) { buffer.removeDependant(this) };
		buffer = argBuffer;
		if (buffer.notNil) { buffer.addDependant(this) };
		thisMethod.report(this, script, buffer);
		script.setProcessParameter(name, buffer.bufnum); // (, *argBuffer);
		script.changed(name, buffer.bufnum); // (, *argBuffer);
//		this.set(buffer.bufnum);
	}
	makeDefaultAction { | envir |
		// the default action is different for TrOutput
		^{ | bufnum, argBuffer |
			if (argBuffer.isKindOf(Buffer)) {
			envir[name] = bufnum;
			this.buffer = argBuffer;
//			script.setProcessParameter(name, bufnum); // (, *argBuffer);
//			script.changed(name, bufnum); // (, *argBuffer);
			thisMethod.report(this, script, buffer);
			}{ thisMethod.report(this, script, bufnum, argBuffer) }
		};
	}
	close {
		super.close;
		this.buffer = nil;
	}
	makeGui { | gui, adapterEnvir |
		var label, /* bufsink, */ numbox, menu, adapter;
		label = SCDragSink(gui, Rect(0,0,100,20)).string_(name)
			.background_(Color(0.9, 0.9, 0.2, 0.3));
/*		bufsink = SCDragSink(gui, Rect(0,0,140,20))
			.string_(" NO BUFFER ")
			.background_(Color(0.3, 0.6, 0.9))
			.font_(Font("Helvetica", 10))
			.canReceiveDragHandler_({ this.canReceiveDragHandler })
			.receiveDragHandler_({ this.receiveDragHandler });
*/		menu = SCPopUpMenu(gui, Rect(0, 0, 140, 20));
		{ thisMethod.report(samples); } ! 100;
		menu.items = samples.buffers.keys.asArray.sort;
		menu.font = Font("Helvetica", 10);
		menu.action = {
			var bnum, bname;
			bname = menu.items[menu.value];
			buffer = samples.at(bname);
//			this.set(buffer.index, )
			bnum = buffer.bufnum;
			action.(bnum);
			script.changed(name, bnum, bname);
			thisMethod.report(this, script, buffer, bname);
		};
		menu.keyDownAction =  { | me, char, mod, unicode |
			// do not react to space key bubbled from top view!
			//	if (char == $ , { me.valueAction = me.value + 1; ^me });
			switch (char,
				$\r, { me.valueAction = me.value + 1; },
				$\n, { me.valueAction = me.value + 1; },
				3.asAscii, { me.valueAction = me.value + 1; },
				{
					switch (unicode,
						16rF700, { me.valueAction = me.value + 1; },
						16rF703, { me.valueAction = me.value + 1; },
						16rF701, { me.valueAction = me.value - 1; },
						16rF702, { me.valueAction = me.value - 1; }
					)
				}
			)
		};
		numbox = SCNumberBox(gui, Rect(0,0,50,20));
		numbox.canFocus = false;
		numbox.value = script.envir[name];
		adapter = { | sender, whatChanged, args |
			thisMethod.report(sender, whatChanged, args);
			switch (whatChanged,
				\bufList, {
					{ menu.items = args; }.defer;
					// must set selection to actual buffer on menu! : ...
				},
				\deleted, {
					thisMethod.report(this, \deletedBuffer, args); // since deleted: 
					script.set(name, 0); // set to empty buffer
				}
			);
		};
		samples.addDependant(adapter);
		menu.onClose = { samples.removeDependant(adapter); };
		// update slider knob color when midi responder activation state changes: 
		// TODO: examine if BufParameter is midiable, use label color to indicate active status
/*		adapterEnvir[midiName] = { | isOn |
			if (isOn) {
//				menu.knobColor = Color.red;
			}{
//				menu.knobColor = Color.clear;
			}
		};
*/		adapterEnvir[name] = { | bufnum |
			{
				var bufname;
				thisMethod.report(menu.items, bufnum, menu.items[bufnum]);
//				menu.value = 
				numbox.value = bufnum = bufnum.round(1).asInteger;
				buffer = samples.buffers.detect {|b| b.bufnum == bufnum };				
//				thisMethod.report(this, name, bufnum, buffer);
				if (buffer.notNil) {
					bufname = samples.buffers.findKeyForValue(buffer);
/*					bufsink.string = bufname ++ "(" ++
					((buffer.numFrames ? 0) / (buffer.sampleRate ? 44100)).round(0.01).asString
					++ ")";
*/
					menu.value = menu.items.indexOf(bufname) ? 0;
				};
			}.defer;
		};
		// update label color when midi responder activation state changes: 
		// perform update of your gui after construction, thereby setting gui items
		script.changed(name, script.envir[name]);
	}
	labelBackground { ^Color.yellow.alpha_(0.1) }
	canReceiveDragHandler { | dragsink, numbox, gui |
		var object;
		object = SCView.currentDrag;
		if (object.isKindOf(MIDIResponder)) { ^true };
		^object.isKindOf(Buffer);
	}
	receiveDragHandler {
		if (SCView.currentDrag.isKindOf(MIDIResponder)) {
			this.setMIDIResponder(SCView.currentDrag);
		}{
			action.(SCView.currentDrag.bufnum ? 0);
		}
	}
	// --------------- Preset saving / loading ---------------
	getPreset {
	// return data for saving current setting as preset
	// return name of buffer as identifier instead of numeric value
		^if (buffer.notNil) { buffer.path.fileSymbol } { nil };
	}
	setPreset { | argValue |
		// restore value from data saved on preset.
		this.set(Samples.all[script.session.server][argValue.asSymbol].bufnum);
	}
	// --------------- MIDI ---------------
	// attempt at midiability: 
/*	canAutoMidiSetup {
		^false;
	}*/
	// attempt at midiability ...
	activateMidi {
		super.activateMidi;
		this.update(Samples.default, \bufList);
		samples.addDependant(this);
	}
	deactivateMidi {
		super.deactivateMidi;
		samples.removeDependant(this);
	}
	update2 {
		thisMethod.report(this);
	}
	/*
	update { | who, what |
		// buf parameters add themselves to Samples so that they can update 
		// their menu and specs when a buffer is loaded or freed. 
		// this makes it possible to scroll through the list of samples.buffers
		// when midi is received on this parameter 
//		[this, who, what].postln;
		{ thisMethod.report(who, what); }.defer(0.1);
/*		switch (
			what,
			\samples, { thisMethod.report("samples");
//				spec.maxval = (who.buffers.size - 1) max: 0;
			},
			\info, { thisMethod.report(who, "info");
//				this.buffer = who;
			}
		)
*/	}
*/
}
