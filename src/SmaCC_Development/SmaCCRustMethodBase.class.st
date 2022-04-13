Class {
	#name : #SmaCCRustMethodBase,
	#superclass : #Object,
	#instVars : [
		'arguments',
		'modifier',
		'name',
		'source'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'as yet unclassified' }
SmaCCRustMethodBase class >> name: nameString arguments: aCollection source: aSourceString [
	^ (self new)
		name: nameString
			arguments: aCollection
			source: aSourceString;
		yourself
]

{ #category : #accessing }
SmaCCRustMethodBase >> arguments [

	^ arguments
]

{ #category : #accessing }
SmaCCRustMethodBase >> arguments: anObject [

	arguments := anObject
]

{ #category : #'point functions' }
SmaCCRustMethodBase >> isConstructor [
	^ false
]

{ #category : #accessing }
SmaCCRustMethodBase >> modifier [

	^ modifier
]

{ #category : #'as yet unclassified' }
SmaCCRustMethodBase >> modifierClass [
	^SmaCCRustModifier
]

{ #category : #accessing }
SmaCCRustMethodBase >> name [

	^ name
]

{ #category : #accessing }
SmaCCRustMethodBase >> name: anObject [

	name := anObject
]

{ #category : #'as yet unclassified' }
SmaCCRustMethodBase >> name: nameString arguments: aCollection source: aSourceString [
	name := nameString.
	arguments := aCollection.
	source := aSourceString.
	modifier := self modifierClass new
]

{ #category : #saving }
SmaCCRustMethodBase >> saveArgumentsOn: aWriteStream [
	aWriteStream nextPut: $(.
	arguments do: [ :each | each saveShortDefinitionOn: aWriteStream ] separatedBy: [ aWriteStream nextPutAll: ', ' ].
	aWriteStream nextPutAll: ') '
]

{ #category : #saving }
SmaCCRustMethodBase >> saveOn: aWriteStream [
	self subclassResponsibility
]

{ #category : #saving }
SmaCCRustMethodBase >> saveSourceOn: aWriteStream [
	aWriteStream
		nextPut: ${;
		cr.
	source notEmpty
		ifTrue:
			[ aWriteStream
				tab;
				tab;
				tab;
				nextPutAll:
						(source
								copyReplaceAll: (String with: Character cr with: Character lf)
								with: (String with: Character cr with: Character lf) , '			');
				cr ].
	aWriteStream
		tab;
		tab;
		nextPut: $}
]

{ #category : #'point functions' }
SmaCCRustMethodBase >> sortsBefore: aSmaCCCSharpMethodBase [
	self isConstructor ~= aSmaCCCSharpMethodBase isConstructor ifTrue: [ ^ self isConstructor ].
	(self modifier sortsBefore: aSmaCCCSharpMethodBase modifier) ifTrue: [ ^ true ].
	(aSmaCCCSharpMethodBase modifier sortsBefore: self modifier) ifTrue: [ ^ false ].
	^ self name < aSmaCCCSharpMethodBase name
]

{ #category : #accessing }
SmaCCRustMethodBase >> source [

	^ source
]

{ #category : #accessing }
SmaCCRustMethodBase >> source: anObject [

	source := anObject
]
