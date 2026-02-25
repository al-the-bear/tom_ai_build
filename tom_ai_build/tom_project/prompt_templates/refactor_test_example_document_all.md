**Prompt 1**

1. go through all subfolders of the tombase folder exception observable, timezoned and reflection and refactor and document the files according to the guidelines in coding_guidelines.md. Don't change the functionality or don't remove or add additional public methods, member or accessors. Of course you can introduce new private members, methods and accessors.

2. go through all subfolders of the tombase folder exception observable, timezoned and reflection and create comprehensive examples according to the guidelines in examples.md. The number of examples should vary depending on the number of methods, classes etc. in the package to make sure the examples really cover every important aspect of the functionality.

3. go through all subfolders of the tombase folder exception observable, timezoned and reflection and create comprehensive tests according to the guidelines in tests.md. The number of tests should vary depending on the number of methods, classes etc. in the package to make sure the test really cover every important aspect of the functionality.

4. Make sure all the examples and tests run. Add files to build.yaml for generation using the reflectable generator as needed and import them and initialize reflectable. Fix any bugs you find.

5. go through all subfolders of the tombase folder exception observable, timezoned and reflection and create a package documentation file according to the guidelines in documentation_guidelines.md. The length of the documentation should vary depending on the number of methods, classes etc. in the package to make sure the documentation really covers every important aspect of the functionality. The name of the file should match the folder name, for example for folder http the file should be named http.md

6. go through all subfolders of the tombase folder and create the API file with name api.dart according to the API file creation rules in api.md in the api subfolder. Delete any existing api.dart is neccessary.

7. Read the complete newly generated api.dart file and double check that the api listed in the file actually matches the code.

8. Go through all folders and doublecheck that the documentation cover all public classes, methods and member. Then double check that the documentation doesn't show features that don't actually exist in the code. Extract the code samples from the documentation into an additional example file and make sure the examples actually run. Update the documentation if changes are required to make the code examples run.

**Prompt 2**

Please go through the following tasks in the given order, I have used sqare brackets to make it easy to see where a group starts and where it ends:

Group 1: 
[
Revise the examples.md document to make sure it is mentioned that the examples must be executable code, not printed to the console.
]

Group 2:
[
Revise all examples, use the guidelines in examples.md. There is a still lot of code printed, but hardly any code that is actually executed. Please create example which actually execute sample code instead of printing it. Example quality and usefulness for future users of the framework is priority.

Always use the code in tom_uam_client, tom_uam_server, tom_uam_shared and the sometimes derived module in the tom_client/tom_server source folders to understand the intended usage better.
]


Always use the code in tom_uam_client, tom_uam_server, tom_uam_shared and the sometimes derived module in the tom_client/tom_server source folders to understand the intended usage better.

1. Please update the documentation for the aforementioned modules according to documentation_guidelines.md.
2. Please update the examples for the aforementioned modules according to examples.md.
3. Please update the tests for the aforementioned modules according to tests.md.
4. Verify that examples and tests actually run.
5. Doublecheck that the documentation covers all parts of the code, update the documentation is something is missing
6. Doublecheck that the tests cover all parts of the code, add additional tests if something is not covered
7. Doublecheck that the example cover all parts of the code and the typical usage scenarios, add additional examples is something is not covered
]

**Modules**

Modules:
    /tombase/beanlocator
    /tombase/context
    /tombase/crypte
    /tombase/http_connection
    /tombase/isolate_pooling
    /tombase/json
    /tombase/little_things
    /tombase/logging
    /tombase/observable
    /tombase/reflection
    /tombase/resources
    /tombase/runtime
    /tombase/security
    /tombase/settings
    /tombase/shutdown_cleanup
    /tombase/timezoned




