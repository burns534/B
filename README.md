The interpreter currently has memory leaks due to variable reassignments. I may fix this later, but it will be inconsequential for bootstrapping the compiler.

Will also have a memory leak in activation stack which could be fixed pretty easily but shouldn't matter