Class {
	#name : #SmaCCRustMethod,
	#superclass : #Object,
	#instVars : [
		'arguments',
		'modifier',
		'name',
		'source',
		'type'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'as yet unclassified' }
SmaCCRustMethod class >> name: nameString arguments: aCollection source: aSourceString [
	^ (self new)
		name: nameString
			arguments: aCollection
			source: aSourceString;
		yourself
]

{ #category : #accessing }
SmaCCRustMethod class >> type: typeString name: nameString arguments: aCollection source: aSourceString [
	^ self new
		type: typeString
		name: nameString
		arguments: aCollection
		source: aSourceString
]

{ #category : #accessing }
SmaCCRustMethod >> arguments [

	^ arguments
]

{ #category : #accessing }
SmaCCRustMethod >> arguments: anObject [

	arguments := anObject
]

{ #category : #'point functions' }
SmaCCRustMethod >> isConstructor [
	^ false
]

{ #category : #accessing }
SmaCCRustMethod >> modifier [

	^ modifier
]

{ #category : #'as yet unclassified' }
SmaCCRustMethod >> modifierClass [
	^SmaCCRustModifier
]

{ #category : #accessing }
SmaCCRustMethod >> name [

	^ name
]

{ #category : #accessing }
SmaCCRustMethod >> name: anObject [

	name := anObject
]

{ #category : #'as yet unclassified' }
SmaCCRustMethod >> name: nameString arguments: aCollection source: aSourceString [
	name := nameString.
	arguments := aCollection.
	source := aSourceString.
	modifier := self modifierClass new
]

{ #category : #saving }
SmaCCRustMethod >> saveArgumentsOn: aWriteStream [
	aWriteStream nextPut: $(.
	arguments do: [ :each | each saveShortDefinitionOn: aWriteStream ] separatedBy: [ aWriteStream nextPutAll: ', ' ].
	aWriteStream nextPutAll: ') '
]

{ #category : #saving }
SmaCCRustMethod >> saveOn: aWriteStream [
	modifier saveOn: aWriteStream.
	aWriteStream
		nextPutAll: 'fn ';
		nextPutAll: name.
	self saveArgumentsOn: aWriteStream.
	aWriteStream
		nextPutAll: ' -> ';
		nextPutAll: type.
	self saveSourceOn: aWriteStream
]

{ #category : #saving }
SmaCCRustMethod >> saveSourceOn: aWriteStream [
	aWriteStream
		nextPut: ${;
		cr.
	source notEmpty
		ifTrue:
			[ source lines
				do:
					[ :line | 
					aWriteStream
						tab; tab; tab;
						nextPutAll: line;
						cr ] ].
	aWriteStream
		tab;
		tab;
		nextPut: $}
]

{ #category : #'point functions' }
SmaCCRustMethod >> sortsBefore: aSmaCCCSharpMethodBase [
	self isConstructor ~= aSmaCCCSharpMethodBase isConstructor ifTrue: [ ^ self isConstructor ].
	(self modifier sortsBefore: aSmaCCCSharpMethodBase modifier) ifTrue: [ ^ true ].
	(aSmaCCCSharpMethodBase modifier sortsBefore: self modifier) ifTrue: [ ^ false ].
	^ self name < aSmaCCCSharpMethodBase name
]

{ #category : #accessing }
SmaCCRustMethod >> source [

	^ source
]

{ #category : #accessing }
SmaCCRustMethod >> source: anObject [

	source := anObject
]

{ #category : #accessing }
SmaCCRustMethod >> type [

	^ type
]

{ #category : #accessing }
SmaCCRustMethod >> type: anObject [

	type := anObject
]

{ #category : #'as yet unclassified' }
SmaCCRustMethod >> type: typeString name: nameString arguments: aCollection source: aSourceString [
	type := typeString.
	self
		name: nameString
		arguments: aCollection
		source: aSourceString
]
