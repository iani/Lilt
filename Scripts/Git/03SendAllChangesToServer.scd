/* iz Friday; January 15, 2010: 7:25 AM
Send all current changes to server. 

This version is for after you have performed the first commit. 

This is configured for Lilt. 

*/

~script.routine {
	// list all files in the User Application Support Directory of SuperCollider
	("cd " ++ Platform.userAppSupportDir.replace(" ", "\\ ") ++ "/Extensions/Lilt
ls -a
git push").runInTerminal;
	1.0.wait;
};
