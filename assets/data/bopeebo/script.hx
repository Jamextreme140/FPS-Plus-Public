function onCreate() {
	trace("Created!");
}

function onBeatHit(curBeat) {
	if(curBeat % 8 == 0)
		trace(curBeat);
}