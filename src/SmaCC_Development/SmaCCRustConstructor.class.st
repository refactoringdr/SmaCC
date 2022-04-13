Class {
	#name : #SmaCCRustConstructor,
	#superclass : #SmaCCRustMethodBase,
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #generated }
SmaCCRustConstructor >> initializer: aString [
]

{ #category : #testing }
SmaCCRustConstructor >> isConstructor [
	^ true
]

{ #category : #saving }
SmaCCRustConstructor >> saveOn: aWriteStream [
	modifier saveOn: aWriteStream.
	aWriteStream nextPutAll: name.
	self saveArgumentsOn: aWriteStream.
"	initializer notNil
		ifTrue:
			[ aWriteStream
				nextPutAll: ': ';
				nextPutAll: initializer;
				space ]."
	self saveSourceOn: aWriteStream
]
