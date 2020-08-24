import { Coverage } from "../node_modules/stalker-coverage/dist/coverage";
/*
 * This sample replaces the 'main' function of the target application with one which starts
 * collecting coverage information, before calling the original 'main' function. Once the
 * original 'main' function returns, coverage collection is stopped. This coverage
 * information is written into a file which can then be directly loaded into IDA lighthouse
 * or Ghidra Dragondance.
 */

/*
 * The address of the symbol 'main' which is to be used as the start and finish point to
 * collect coverage information.
 */
const mainAddress = DebugSymbol.fromName("main").address;

/**
 * The main module for the program for which we will collect coverage information (we will
 * not collect coverage information for any library dependencies).
 */
const mainModule = Process.enumerateModules()[0];

/*
 * A NativeFunction type for the 'main' function which will be used to call the original
 * function.
 */
const mainFunctionPointer = new NativeFunction(
    mainAddress,
    "int",
    ["int", "pointer"],
    { traps : "all"});

/*
 * A function to be used to replace the 'main' function. This function will start collecting
 * coverage information before calling the original 'main' function. Once this function
 * returns, the coverage collection will be stopped and flushed. Note that we cannot use
 * Interceptor.attach here, since this interferes with Stalker (which is used to provide the
 * coverage data).
 */
const mainReplacement = new NativeCallback(
    (argc, argv) => {
        const coverageFileName = `${mainModule.path}.dat`;
        const coverageFile = new File(coverageFileName, "wb+");

        const coverage = Coverage.start({
            moduleFilter: (m) => Coverage.mainModule(m),
            onCoverage: (coverageData) => {
                coverageFile.write(coverageData);
            },
            threadFilter: (t) => Coverage.currentThread(t),
        });

        const ret = mainFunctionPointer(argc, argv) as number;

        coverage.stop();
        coverageFile.close();

        return ret;
    },
    "int",
    ["int", "pointer"]);

/*
 * Replace the 'main' function with our replacement function defined above.
 */
Interceptor.replace(mainAddress, mainReplacement);
