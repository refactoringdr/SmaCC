Class {
	#name : #SmaCCRustClass,
	#superclass : #Object,
	#instVars : [
		'name',
		'superclass',
		'model',
		'methods',
		'variables',
		'methodStrings',
		'doNotGenerate',
		'staticStrings'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'instance creation' }
SmaCCRustClass class >> newName: aString [ 
	^(self new)
		name: aString;
		yourself
]

{ #category : #adding }
SmaCCRustClass >> addVariable: nameString type: typeString [
	^ variables add: (self variableClass name: nameString type: typeString)
]

{ #category : #compiling }
SmaCCRustClass >> compile: origName type: typeString arguments: aCollection source: sourceString [
	| existing method nameString |
	nameString := origName copy.
	existing := self methodsNamed: nameString.
	method := existing
		detect: [ :each | each type = typeString and: [ each arguments asArray = aCollection asArray ] ]
		ifNone:
			[ methods
				add:
					(self methodClass
						type: typeString
						name: nameString
						arguments: aCollection
						source: sourceString) ].
	method source: sourceString.
	^ method
]

{ #category : #visiting }
SmaCCRustClass >> compileConstructorArguments: aCollection source: sourceString [ 
	^methods add: (self constructorClass 
				type: 'Scanner<''a>'
				name: 'on<''a>'
				arguments: aCollection
				source: sourceString)
]

{ #category : #compiling }
SmaCCRustClass >> compileMethod: aString [
	methodStrings add: aString
]

{ #category : #compiling }
SmaCCRustClass >> compileStatic: aString [
	staticStrings add: aString
]

{ #category : #accessing }
SmaCCRustClass >> constructorClass [
	^ SmaCCRustMethod
]

{ #category : #accessing }
SmaCCRustClass >> doNotGenerate [

	^ doNotGenerate
]

{ #category : #accessing }
SmaCCRustClass >> doNotGenerate: anObject [

	doNotGenerate := anObject
]

{ #category : #actions }
SmaCCRustClass >> fileName [
	^ self simpleName , '.rs'
]

{ #category : #accessing }
SmaCCRustClass >> methodClass [
	^SmaCCRustMethod
]

{ #category : #model }
SmaCCRustClass >> methodsNamed: aString [
	^ methods select: [ :each | each name = aString ]
]

{ #category : #accessing }
SmaCCRustClass >> model [

	^ model
]

{ #category : #accessing }
SmaCCRustClass >> model: aSmaCCRustModel [

	model := aSmaCCRustModel
]

{ #category : #accessing }
SmaCCRustClass >> name [

	^ name
]

{ #category : #accessing }
SmaCCRustClass >> name: anObject [
	name := anObject.
	variables := OrderedCollection new.
	methods := OrderedCollection new.
	methodStrings := Set new.
	staticStrings := Set new.
	doNotGenerate := false
]

{ #category : #actions }
SmaCCRustClass >> namespace [
	| index |
	index := name lastIndexOf: $. ifAbsent: [ 0 ].
	^ index > 0 ifTrue: [ name copyFrom: 1 to: index - 1 ] ifFalse: [ 'Refactory.SmaCC' ]
]

{ #category : #actions }
SmaCCRustClass >> save [
	self doNotGenerate ifTrue: [ ^ self ].
	(self fileName asFileReference)
		ensureDelete;
		writeStreamDo: [ :stream | self saveOn: stream ]
]

{ #category : #actions }
SmaCCRustClass >> saveOn: aWriteStream [
	aWriteStream
		nextPutAll: 'use crate::SmaCC::*;';
		cr;
		nextPutAll: 'use std::collections::HashMap;';
		cr;
		nextPutAll: 'use lazy_static::lazy_static;';
		cr.
	variables
		do:
			[ :each | 
			aWriteStream
				cr;
				tab;
				tab.
			each saveOn: aWriteStream ].
	(methods asSortedCollection: [ :a :b | a sortsBefore: b ])
		do:
			[ :each | 
			aWriteStream
				cr;
				cr;
				tab;
				tab.
			each saveOn: aWriteStream ].
	methodStrings asSortedCollection
		do:
			[ :each | 
			aWriteStream
				cr;
				nextPutAll: each;
				cr ].
	staticStrings asSortedCollection
		do:
			[ :each | 
			aWriteStream
				cr;
				nextPutAll: each;
				cr ]
]

{ #category : #visiting }
SmaCCRustClass >> simpleName [
	^name
]

{ #category : #accessing }
SmaCCRustClass >> superclassName: aString [
	superclass := aString 
]

{ #category : #compiling }
SmaCCRustClass >> variableClass [
	^ SmaCCRustVariable
]
