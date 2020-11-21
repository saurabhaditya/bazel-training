goog.provide('templates.Greeter');

goog.require('goog.soy');
goog.require('templates.soy.greeter');

/**
 * Greeter page.
 * @param {string} name Name of person to greet.
 * @constructor
 * @final
 */
templates.Greeter = function(name) {
    /**
     * Name of person to greet.
     * @private {string}
     * @const
     */
    this.name_ = name;
};

/**
 * Renders HTML greeting as document body.
 */
templates.Greeter.prototype.greet = function() {
    goog.soy.renderElement(goog.global.document.body,
        templates.soy.greeter.greet,
        {name: this.name_});
};
