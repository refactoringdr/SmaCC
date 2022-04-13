Class {
	#name : #SmaCCRustModifier,
	#superclass : #Object,
	#instVars : [
		'modifiers'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'point functions' }
SmaCCRustModifier >> defaultVisibility [
	^ ''
]

{ #category : #'point functions' }
SmaCCRustModifier >> isStatic [
	^ self modifiers includes: 'static'
]

{ #category : #accessing }
SmaCCRustModifier >> modifiers [
	modifiers isNil ifTrue: [ modifiers := OrderedCollection new ].
	^ modifiers
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> override [
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> private [
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> protected [
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> public [
	self removeVisibilityModifiers.
	self modifiers add: 'pub'
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> removeModifiers: modifiersToRemove [
	modifiersToRemove do: [ :each | self modifiers remove: each ifAbsent: [  ] ]
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> removeVisibilityModifiers [
	self removeModifiers: self visibilityModifiers
]

{ #category : #saving }
SmaCCRustModifier >> saveOn: aWriteStream [
	self modifiers
		do:
			[ :each | 
			aWriteStream
				nextPutAll: each;
				space ]
]

{ #category : #'point functions' }
SmaCCRustModifier >> sortPosition [
	^ (self visibilityModifiers indexOf: self visibility)
		- (self isStatic ifTrue: [ self visibilityModifiers size ] ifFalse: [ 0 ])
]

{ #category : #'point functions' }
SmaCCRustModifier >> sortsBefore: aSmaCCCSharpModifier [
	^ self sortPosition < aSmaCCCSharpModifier sortPosition
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> static [
]

{ #category : #'point functions' }
SmaCCRustModifier >> visibility [
	^ self modifiers detect: [ :each | self visibilityModifiers includes: each ] ifNone: [ self defaultVisibility ]
]

{ #category : #'as yet unclassified' }
SmaCCRustModifier >> visibilityModifiers [
	^ #('pub')
]
