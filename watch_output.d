#!/usr/bin/env dub
/+ dub.sdl:
    name "test-watch"
    version "1.0.0"
    license "public domain"
    dependency "fswatch" version="~>0.5"
+/

import core.thread;
import fswatch;
import std.algorithm.searching : any;
import std.datetime;
import std.process;
import std.string;

void main(string[] args)
{
    FileWatch sourceWatcher = FileWatch("source/", true);
    FileWatch testWatcher = FileWatch("test/", true);

    runTests(args);

    while (true)
    {
        FileChangeEvent[] sourceChanges = sourceWatcher.getEvents();
        FileChangeEvent[] testChanges = testWatcher.getEvents();

        if (sourceChanges.length > 0 || testChanges.length > 0)
        {
            runTests(args);
        }

        Thread.sleep(500.msecs);
    }
}

private void runTests(string[] args)
{
    Pid clearPid = spawnShell("clear");
    wait(clearPid);
    Pid dubTestPid = spawnProcess(["dub", "run", "--config=output_test", "--compiler=dmd"] ~ args[1..$]);
    wait(dubTestPid);
}
