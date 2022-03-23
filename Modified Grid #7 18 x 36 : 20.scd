// The code below is a subtle modification from code provided by Yota Morimoto who has developed this cool grid interface and randomization tool

(
p = ServerOptions.new;
s.makeWindow;// for recording
p.memSize = 128000;


s.newBusAllocators;
s.freeAll;
Buffer.freeAll;

Window.closeAll;

s.boot;
s.dumpOSC;
)

(

// set up groups & busses
~sourceGrp = Group.new(s);
~fxGrp = Group.after(~sourceGrp);
~effectBus = Bus.audio(s,2);


// how many
n = 18;
y = 36;

// grid of nxn
~grid = 0!n!y;

// our process

//~process = {1.0.rand2};
//~process = {[0, 0.25, 0.5, 0.75, 1].choose};
~process = {[0, 0, 0, 0, 0, 0, 0.2, 0.4, 0.6, 0.8, 1, 1, 1].choose};

// our wait
~wait = 1/6;


~frequencies = [100, 200, 400, 800, 1600, 3200];
~bassfrequencies = ~frequencies/4;
// send return signal

~direct = 0.7;

// delay time factor

~delaytime = 8;

// the process
r = Routine {
	loop {
		// run the process
		~update.(~process);

				s.makeBundle(0.2,{

			Synth(\yotassine,[
				freq: ~grid[0][14]*~frequencies.choose,
				phase:~grid[0][12]*pi,
				amp:~grid[0][10]*0.2,
				//amp: 0.2,
				dur:~grid[0][8],
				//dur: 0.4,
				pan:~grid[0][6]*[-1,1].choose,
				atk: 0.01,
				//rel: ~grid[0][1]*0.5,
				rel: 0.3,
				effectBus: ~effectBus,
                filterfreq:~grid[0][5]*[300,500, 1000, 2000, 5000].choose,
				direct: ~direct, // direct = 1 is no effects
				out: 0,
				target:~sourceGrp,
			]);


			Synth(\sine,[
				freq: ~grid[0][4]*~frequencies.choose,//uses array 0 item 5
				phase:~grid[0][5]*pi,
				ffreq:~grid[0][2]*[200,800,1600, 3200].choose,
				amp:~grid[0][6]*0.2,
				//amp: 0.2,
				dur:~grid[0][7],
				//dur: 0.4,
				pan:~grid[0][8]*[-1,1].choose,
				atk: 0.01,
				//rel: ~grid[0][1]*0.5,
				rel: 0.3,
				effectBus: ~effectBus,
				direct: 0.5, // direct = 1 is no effects
				out: 0,
				target:~sourceGrp,
			]);



			Synth(\sine2,[
				freq: ~grid[0][7]*~bassfrequencies.choose,//uses array 0 item 8
				//phase:~grid[0][5]*pi,
				//amp:~grid[0][6]*0.3,
				amp: 0.4,
				//dur:~grid[0][7],
				dur: 0.2,
				pan:~grid[0][1]*[-1,1].choose,
				atk: 0.05,
				//rel: ~grid[0][1]*0.5,
				rel: 0.3,
				//effectBus: ~effectBus,
				direct: 1, // direct = 1 is no effects
				effectBus: ~effectBus,
				out: 0,
				target:~sourceGrp,
			]);



			Synth(\sine3,[
			    freq: ~grid[0][0]*~bassfrequencies.choose,//uses array 0 item 5
				//phase:~grid[0][5]*pi,
				//amp:~grid[0][6]*0.3,
				amp: 0.4,
				//dur:~grid[0][7],
				dur: 0.2,
				pan:~grid[0][1]*[-1,1].choose,
				atk: 0.05,
				//rel: ~grid[0][1]*0.5,
				rel: 0.3,
				//effectBus: ~effectBus,
				direct: 1, // direct = 1 is no effects
				effectBus: ~effectBus,
				out: 0,
				target:~sourceGrp,
			]);



			Synth(\cymbal,[
				time: 400,
				baseFreq: ~grid[0][4]*[300,500, 1000, 2000, 5000].choose,
				amp:~grid[0][2]*0.2,
				direct: ~direct, // direct = 1 is no effects
				effectBus: ~effectBus,
				out: 0,
				target:~sourceGrp,
			]);



			Synth(\ping_mh,[
				freq: ~grid[0][0]*~frequencies.choose,
				amp:~grid[0][1]*0.5,
				direct: 0.5, // direct = 1 is no effects
				effectBus: ~effectBus,
				out: 0,
				target:~sourceGrp,
				pan: ~grid[0][3],
			]);




		});

		// drawing
		// we need to defer!
		{ v.refresh }.defer;

		// then
		~wait.().wait;
	}
};
// drawing func
~pen = (
	grid: {
		36.do { |i|
			18.do { |j|
				Pen.fillColor = Color.grey(~grid[i][j]*0.5+0.5, alpha: 0.7);
				Pen.fillRect(Rect(j*z, i*z, z-2, z-2));
				};
		};
	},

);

~update = { |f|
	35.do { |i| // enter total number of rows minus 1
		18.do { |j| // enter total number of columns
			~grid[35-i][j] = ~grid[34-i][j]; // first enter total number of rows minus 1 and then minus 2
		};
	};
	18.do { |i| ~grid[0][i] = f.() }; // enter total number of columns
};

// SynthDefs

SynthDef(\yotassine, { |freq,phase,amp,atk, rel,pan, effectBus, direct, out=0, filterfreq |
	var sig,env;
	sig = FSinOsc.ar(freq,phase,amp);
	env = Env.perc(atk, rel).kr(2);
	sig = Pan2.ar(sig*env,pan);
	sig = RHPF.ar(sig, filterfreq);
	Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;


SynthDef(\sine, { |freq,phase,amp=0.5,atk,rel,ffreq = 500, pan, out=0, effectBus, direct = 0.8 |
	var sig,env;
	sig = FSinOsc.ar(freq,phase,amp);
	env = Env.perc(atk, rel).kr(2);
	sig = RLPF.ar(sig*2, ffreq);
	sig = Pan2.ar(sig*env,pan);
    Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;

SynthDef(\sine2, { |freq,phase,amp=0.5,atk,rel,pan, out=0, effectBus, direct = 0.8 |
	var sig,env;
	sig = FSinOsc.ar(freq,phase,amp);
	env = Env.perc(atk, rel).kr(2);
	sig = Pan2.ar(sig*env,pan);
    Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;

SynthDef(\sine3, { |freq,phase,amp=0.5,atk,rel,pan, out=0, effectBus, direct = 0.8 |
	var sig,env;
	sig = FSinOsc.ar(freq,phase,amp);
	env = Env.perc(atk, rel).kr(2);
	sig = Pan2.ar(sig*env,pan);
    Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;

SynthDef(\cymbal, {
	arg out=0, baseFreq = 300, time = 100, amp=0.1, effectBus, direct = 0.5;
	var freqs = [baseFreq, baseFreq*1.3420, baseFreq*1.2312, baseFreq*1.6532, baseFreq*1.9523, baseFreq*2.1523];
	var sig, pulseEnv;
	pulseEnv = EnvGen.ar(Env.new([1.0, 0.6], [time], [-0.5]), timeScale:(1/1000));
	sig = Mix.new(LFPulse.ar(freqs * 4.09));
	sig = (BinaryOpUGen('==', sig, 6.0) * 0.6) + (BinaryOpUGen('==', sig, 2.0) * 0.2) + (BinaryOpUGen('==', sig, 1.0) * 0.9); // XOR --- don't understand that one quite yet ;-)
	sig = (sig * pulseEnv) + (Mix.new(LFPulse.ar(freqs, width:0.55)) * 0.9);
    sig = RLPF.ar(sig, 7000, 0.6);
    sig = RHPF.ar(sig, 6800, 1.5);
	sig = RHPF.ar(sig, 6800, 1.5);// for some reason, doing this twice, really works!
    sig = RHPF.ar(sig, 1200, 1.5);
	sig = sig * EnvGen.ar(Env.new([0, 1, 0.4, 0, 0], [2, time, 50, 500], [0, -0.5, 0, -50]), timeScale:(1/1000), doneAction:2);
	sig = [sig, DelayN.ar(sig, 0.005, 0.005)];
    Out.ar(out, sig * direct * amp);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct)*amp);
},
metadata: (
	credit: "Published on sc-users 2007-08-25 by Ryan Brown",
	tags: ['808', \hihat, \percussion, \cymbal]
	)
)
.add;


SynthDef(\ping_mh,{arg freq=440,amp=0.2,dur=0.1,attack=0.001,pan=0,out=0, direct = 0.5, effectBus;
    var sig;
    freq=freq*rrand(1,1.01);
    e=EnvGen.ar(Env.perc(attack,dur,curve:-4),doneAction:2);
    sig=SinOsc.ar(freq,0,amp*e);
    sig=Pan2.ar(sig,pan);
    Out.ar(out, sig * direct * amp);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct)*amp);
},
metadata: (
	credit: "Your basic percussive synth instrument, a good default sound for testing patterns, etc.",
	tags: [\percussive, \ping, \default, \simple, \stereo, \detuned, \tuned]
	)
).add;


SynthDef(\verb, {
	var sig,fb, amp = 0.5;
	sig = ~effectBus.ar(2);
	sig = HPF.ar(sig,200);
	5.do { sig = AllpassN.ar(sig, 0.05, {0.050.rand}!2, 1) };
	fb = LocalIn.ar(2)*0.8;
	fb = AllpassN.ar(fb, 0.05, 0.050.rand, 2);
	fb = DelayN.ar(fb, 0.1, 0.1);
	fb = Rotate2.ar(fb[0], fb[1], 0.23);
	sig = fb + sig;
	sig = sig * amp;
	LocalOut.ar(sig);
	Out.ar(0, sig);
}).add;

SynthDef(\delay, {
	var sig, amp = 0.5, pan = 0;
	sig = LocalIn.ar(2)*0.8;
	sig = ~effectBus.ar(2);
	sig = DelayL.ar(sig, ~wait*~delaytime, ~wait*~delaytime);
	sig = sig * amp;
	sig = Pan2.ar(sig, pan);
	LocalOut.ar(sig);
	Out.ar(0, sig);
}).add;


w = Window("18 x 36 / 20", Rect(400.0, 285.0, 380.0, 770.0));
z = 20;
v = UserView.new;
v.drawFunc = ~pen[\grid];
w.layout = VLayout(
	Button.new
	.canFocus_(false)
	.states_([
		[">",  Color.grey,Color.white],
		[":.", Color.white,Color.grey(0.3,0.8)]
	])
	.action_({ |b|
		if(b.value==1, {
			r.reset;
			// start process
			// reverb & delay

            Synth.new(\verb,[\in,~effectBus, \out,0], ~fxGrp);
			Synth.new(\delay,[\in,~effectBus, \out,0, \amp, 0.3, \pan, Pwhite(-1, 1, inf)], ~fxGrp);

			SystemClock.play(r);
		}, { r.stop })
	}),
	v
);
CmdPeriod.doOnce {
	r.stop;
	w.close;
};
w.front;
)


// changing processes on the fly


~process = Prand([0,1], inf).asStream;
~process = Pseq([0],inf).asStream;// stops the sound
~process = Prand([0, 0.2, 0.4], inf).asStream;
~process = Prand([0, 0.2, 0.4, 0.6, 0.8, 1], inf).asStream;
~process = Pxrand([0, 0, 0, 0, 0.4, 0.6, 0.8, 1, 1, 1, 1], inf).asStream;
~process = Pxrand([0, 0.25, 0.5, 0.75, 1], inf).asStream;
~process = Pxrand([0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1], inf).asStream;


// changing wait/tempo

~wait = 1/6;

// changing frequencies

~frequencies = [100, 200, 400, 800, 1600]/2;
~bassfrequencies = ~frequencies/4;

// send return signal

~direct = 0.3;

// delay time factor

~delaytime = 32;
