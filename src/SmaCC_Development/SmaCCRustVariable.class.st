Class {
	#name : #SmaCCRustVariable,
	#superclass : #Object,
	#instVars : [
		'name',
		'type',
		'modifier',
		'initializer'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'as yet unclassified' }
SmaCCRustVariable class >> name: nameString type: typeString [
	^ (self new)
		name: nameString type: typeString;
		yourself
]

{ #category : #accessing }
SmaCCRustVariable >> initializer [

	^ initializer
]

{ #category : #accessing }
SmaCCRustVariable >> initializer: anObject [

	initializer := anObject
]

{ #category : #accessing }
SmaCCRustVariable >> modifier [

	^ modifier
]

{ #category : #accessing }
SmaCCRustVariable >> modifier: anObject [

	modifier := anObject
]

{ #category : #'as yet unclassified' }
SmaCCRustVariable >> modifierClass [
	^SmaCCRustModifier
]

{ #category : #'as yet unclassified' }
SmaCCRustVariable >> name: nameString type: typeString [
	name := nameString.
	type := typeString.
	modifier := self modifierClass new
]

{ #category : #saving }
SmaCCRustVariable >> saveOn: aWriteStream [
	modifier saveOn: aWriteStream.
	self saveShortDefinitionOn: aWriteStream.
	initializer notNil
		ifTrue:
			[ aWriteStream
				nextPutAll: ' = ';
				nextPutAll:
						(initializer
								copyReplaceAll: (String with: Character cr with: Character lf)
								with:
									(String
										with: Character cr
										with: Character lf
										with: Character tab
										with: Character tab)) ]
]

{ #category : #saving }
SmaCCRustVariable >> saveShortDefinitionOn: aWriteStream [
	aWriteStream
		nextPutAll: type;
		space;
		nextPutAll: name
]
