Class {
	#name : #CurlyBracketWriteStream,
	#superclass : #WriteStream,
	#instVars : [
		'indents',
		'startOfLine',
		'lastWasLeftBracket'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> cr [
	lastWasLeftBracket ifTrue: [ indents := indents + 1 ].
	super cr.
	startOfLine := true
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> indent: anInteger [
	indents := indents + anInteger
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> indentWhile: aBlock [
	self indent: 1.
	aBlock ensure: [ self unindent: 1 ]
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> initialize [
	(self class superclass canUnderstand: #initialize) ifTrue: [ super initialize ].
	startOfLine := true.
	lastWasLeftBracket := false.
	indents := 0
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> nextPut: aCharacter [
	^ [ startOfLine
		ifTrue:
			[ aCharacter == $} ifTrue: [ indents := indents - 1 ].
			indents timesRepeat: [ super nextPut: Character tab ] ].
	startOfLine := false.
	super nextPut: aCharacter ] ensure: [ lastWasLeftBracket := aCharacter == ${ ]
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> nextPutAll: aString [
	aString isEmpty ifTrue: [ ^ aString ].
	^ [ startOfLine
		ifTrue:
			[ aString first == $} ifTrue: [ indents := indents - 1 ].
			indents timesRepeat: [ super nextPut: Character tab ] ].
	startOfLine := false.
	super nextPutAll: aString ] ensure: [ lastWasLeftBracket := aString last == ${ ]
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> on: aCollection [
	self initialize.
	^ super on: aCollection
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> unindent: anInteger [
	indents := indents - anInteger
]

{ #category : #'stop conditions' }
CurlyBracketWriteStream >> with: aCollection [
	self initialize.
	^ super with: aCollection
]
