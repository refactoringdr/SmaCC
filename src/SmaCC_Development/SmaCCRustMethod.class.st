Class {
	#name : #SmaCCRustMethod,
	#superclass : #SmaCCRustMethodBase,
	#instVars : [
		'type'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'as yet unclassified' }
SmaCCRustMethod class >> type: typeString name: nameString arguments: aCollection source: aSourceString [
	^ (self new)
		type: typeString
			name: nameString
			arguments: aCollection
			source: aSourceString;
		yourself
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
