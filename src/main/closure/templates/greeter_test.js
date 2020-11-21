goog.require('goog.asserts');
goog.require('goog.testing.asserts');
goog.require('goog.testing.jsunit');
goog.require('templates.Greeter');

function testGreet() {
    var greeter = new templates.Greeter('Justine');
    greeter.greet();
    var body = document.body;
    goog.asserts.assert(body != null);
    assertHTMLEquals('<p>Hello <b>Justine</b>!', body.innerHTML);
}