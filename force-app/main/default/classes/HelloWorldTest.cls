/**
 * @description Unit tests for HelloWorld.
 */
@isTest
private class HelloWorldTest {

    @isTest
    static void testSayHello_withName() {
        System.assertEquals(
            'Hello, Test!',
            HelloWorld.sayHello('Test'),
            'Expected personalised greeting'
        );
    }

    @isTest
    static void testSayHello_withNull() {
        System.assertEquals(
            'Hello, World!',
            HelloWorld.sayHello(null),
            'Expected generic greeting for null'
        );
    }

    @isTest
    static void testSayHello_withBlank() {
        System.assertEquals(
            'Hello, World!',
            HelloWorld.sayHello('   '),
            'Expected generic greeting for blank string'
        );
    }
}
