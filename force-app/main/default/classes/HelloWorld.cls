/**
 * @description Sample Apex class demonstrating basic patterns.
 * @author      GitHub Actions Skeleton Generator
 */
public with sharing class HelloWorld {

    /**
     * @description Returns a greeting for the provided name.
     * @param  name The name to greet. If blank, returns a generic greeting.
     * @return      A greeting string.
     */
    public static String sayHello(String name) {
        if (String.isBlank(name)) {
            return 'Hello, World!';
        }
        return 'Hello, ' + name + '!';
    }
}