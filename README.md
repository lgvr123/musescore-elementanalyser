
# Element Analyser plugin for MuseScore 3.x
**Element Analyser** is an plugin for MuseScore that allows to retrieve the properties of an element. 

## What's new in 1.1.2 ?
### User Interface
* New option for searching only for **Non-Null elements**. This provides a faster search result, but will hide some properties you might be looking for
* New option for providing the **tick** of the selected element
* Store the last used option for faster re-use.

### Library
* New **dontdig** option ("do not dig into") defining a list of elements to never dig into. This mostly applies when in _include_ mode. The default value contains properties such as `next`, `prev`, `color`, `bbox`, `align`, ...
* New **limitToNotNull** option specifying whether to hide or display the properties that are not defined.

## Features
* It provides a **User Interface** for displaying those properties, as well as
* A **re-usable library** to incorporate debug and element-analyze into your own plugins.

As a User Interface it provides a simple and straightforward analyse of the selected element and its parents.
As a library it provides  rich and highly configurable functions to tailor the analyse needed when building your own plugins.

## Download and Install ##
Download the [last stable version](https://github.com/lgvr123/musescore-elementanalyser/releases).
For installation see [Plugins](https://musescore.org/en/handbook/3/plugins).

## Important remark
The GUI version is a **slow process**. It might give the impression to bring MuseScore unstable. The user might be tempted to force MuseScore down, but it is unnecessary. The window will gets updated at the end of the process.

## Sponsorship ##
[<img src="/support/Button-Tipeee.png" alt="Support me on Tipee" height="50"/>](https://www.tipeee.com/parkingb) 
[<img src="/support/paypal.jpg" alt="Support me on Paypal" height="55"/>](https://www.paypal.me/LaurentvanRoy) 
[<img src="/support/patreon.png" alt="Support me on Patreon" height="25"/>](https://patreon.com/parkingb)

## Usage as library in your own plugins
### Initialisation
You must declare the library in your code:

    import QtQuick 2.9
    import MuseScore 3.0
    import "elementanalayser/elementanalayser.js" as Debug

### "debugO" function
`debugO` is the function to deep-dive into a selected element.

It can be called in different ways:
#### 1. `debugO(label, element)` 
This is the default call of `debugO`. This will provide the following analyse of the element: 
* excluding some properties such as "pos", "color", "bbox", ... 
* going down into the properties to one level maximum,
* going up into parents until it reaches an element of type SEGMENT.

**Example**:

    var element = curScore.selection.elements[0];
    Debug.debugO("note", element);

#### 2. `debugO(label, element, excluded)` 
You can also specify your own list of elements. `excluded` might be a single string, being the name of a property to be excluded or an array of property names to be excluded.  

**Example**:

    var element = curScore.selection.elements[0];
    Debug.debugO("note", element, ["elements", "staff", "part"]);

#### 3. `debugO(label, element, config)` 
debugO is highly configurable. It can receive a json object defining its behaviour.

Json structure:
* `filterList`: array of property names to exclude or include. Can also be a regexp. <br/>Default: [`elements`, `staff`, `page`] + the "dontdig" list.
* `isinclude`:  true|false. Default: false.<br/>Tells whether the filterList list is defining what must be included in the analyse or excluded.
* `hideExcluded`: true|false. Default: false.<br/>In *include* mode, the non included properties will not be further analysed. They can also be hidden from the analyse. The benefit is a smaller analyse output. The risk is missing some properties forgotten in the include list.
* `maxlevel`: number. Must be &ge; 0. Default: 1.<br/>Tells how far to dive into the properties tree. The higher the number, the bigger the analyse output.
* `stopat`: ElementType value. Default: Element.SEGMENT (90).<br/>Tells when to stop analysing the parent tree.
* `dontdig` : array of property names to never investigate. Can also be a regexp. <br/>Default: [`bbox`, `/^pos/i`, `/color/i`, `/align/i`, `next`, `prev`, `nextInMeasure`, `prevInMeasure`, `lastMeasure`, `firstMeasure`, `lastMeasureMM`, `firstMeasureMM`, `prevMeasure`, `nextMeasure`, `prevMeasureMM`, `nextMeasureMM`, `lastTiedNote`, `firstTiedNote`]
* `limitToNotNull`:  true|false. Default: false.<br/>Tells whether to hide or display the properties that are not defined (`undefined` or `null`).

**Example**:

    var element = curScore.selection.elements[0];
    if (element.type !== Element.NOTE) return;
    note = element;
    var debug = {
    	filterList: ["staff", "voice", /track/i, /part/i, /score/i, /excerpt/i, /accidental/],
    	isinclude: true,
    	maxlevel: 1,
    	stopat: Element.SEGMENT,
    	hideExcluded: true,
    };
    Debug.debugO("note", note, debug);

### "compareObjects" function
`compareObjects` does a comparison of series of object according a series of properties.
Its call signature is: `compareObjects(objects, properties, config)` with:
* `objects` : an array of objects
* `properties`: an array of property names to analyse
* `config`: a json file with the same structure as in `debugO`.

**Example**:

    var explore = ["scoreName", "parts.length", "title", "ntracks"];
    var scores = [curScore, curScore.excerpts[0].partScore];
    Debug.compareObjects(scores, explore, {maxlevel: 0});
   
   ### "addLogger" function
`addLogger` adds outputs for the analyse. The default output is the console. You may add other outputs such as files or QML widgets.
Its call signature is `addLogger(loggerfunction)` with; 
* `loggerfunction`: a function of signature `function(text)`.

**Example**:

    Debug.addLogger(
    	function (text) {
    	txtLog.text = txtLog.text + "\n" + text;
    });

## IMPORTANT
NO WARRANTY THE PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW THE AUTHOR WILL BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.





