/* iz Friday; January 15, 2010: 6:55 AM

Go to user SuperCollider home directory. 

This is just a test of String:runInTerminal. 

*/

~script.routine {
	("cd " ++ Platform.userAppSupportDir.replace(" ", "\\ ") ++ "\nls").runInTerminal;
	1.0.wait;
};

~script.routine {
	("cd " ++ Platform.userAppSupportDir.replace(" ", "\\ ") ++ "\nls -a").runInTerminal;
	1.0.wait;
};
