"
SmaCCParserState represents a particular parse in a GLR parser.

Instance Variables:
	isAccepted	<Boolean>	has this parse been accepted
	nodeStack	<SequenceableCollection of: Object>	the stack of objects for this parse
	position	<Integer>	the current position of the scanner
	scannerState	<Symbol> the current state of the scanner
	stateStack	<SequenceableCollection of: Integer>	the stack of states for this parse


"
Class {
	#name : #SmaCCParserState,
	#superclass : #Object,
	#instVars : [
		'stack',
		'isAccepted',
		'scannerState',
		'attributes'
	],
	#category : #'SmaCC_GLR_Runtime'
}

{ #category : #'instance creation' }
SmaCCParserState class >> stack: aSmaCCStack [
  ^self new
     stack: aSmaCCStack;
     yourself
]

{ #category : #'instance creation' }
SmaCCParserState class >> stack: stack scannerState: aSmaCCScannerState [
  ^self new
     stack: stack;
     scannerState: aSmaCCScannerState;
     yourself
]

{ #category : #comparing }
SmaCCParserState >> = anObject [
	^ self == anObject
		or:
			[ self class = anObject class and: [ self stack = anObject stack ] ]
]

{ #category : #accessing }
SmaCCParserState >> attributeNamed: aSymbol [
	^attributes ifNil: [ nil ] ifNotNil: [ attributes at: aSymbol ]
]

{ #category : #accessing }
SmaCCParserState >> attributeNamed: aSymbol put: aValue [
	(attributes ifNil: [ attributes := Dictionary new ]) at: aSymbol put: aValue
]

{ #category : #testing }
SmaCCParserState >> canBeMergedWith: aSmaCCParserState [
	^ self stateStack = aSmaCCParserState stateStack and: [ self scannerState = aSmaCCParserState scannerState ]
]

{ #category : #comparing }
SmaCCParserState >> hash [
	^ self stack hash
]

{ #category : #testing }
SmaCCParserState >> isAccepted [
	^ isAccepted
]

{ #category : #accessing }
SmaCCParserState >> markAccepted [
	isAccepted := true
]

{ #category : #accessing }
SmaCCParserState >> mergeWith: aSmaCCParserStateCollection [
	| stacks |
	stacks := OrderedCollection new: aSmaCCParserStateCollection size + 1.
	stacks add: stack nodeStack.
	aSmaCCParserStateCollection
		do: [ :each | 
			(stacks includes: each nodeStack)
				ifFalse: [ stacks add: each nodeStack ] ].
	stack nodeStack: (SmaCCDeferredChoice mergeStacks: stacks)
]

{ #category : #accessing }
SmaCCParserState >> nodeStack [
  ^stack nodeStack
]

{ #category : #copying }
SmaCCParserState >> postCopy [
	super postCopy.
	attributes notNil
		ifTrue: [ attributes := attributes copy ]
]

{ #category : #accessing }
SmaCCParserState >> runDeferredActionsFor: aSmaCCParser [
	stack runDeferredActionsFor: aSmaCCParser
]

{ #category : #accessing }
SmaCCParserState >> scannerState [
	^ scannerState
]

{ #category : #accessing }
SmaCCParserState >> scannerState: anObject [
	scannerState := anObject
]

{ #category : #accessing }
SmaCCParserState >> stack [
  ^stack
]

{ #category : #'initialize-release' }
SmaCCParserState >> stack: aSmaCCStack [
  stack := aSmaCCStack.
  isAccepted := false
]

{ #category : #accessing }
SmaCCParserState >> stateStack [
  ^stack stateStack
]
