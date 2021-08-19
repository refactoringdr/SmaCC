Class {
	#name : #SmaCCStack,
	#superclass : #Object,
	#instVars : [
		'states',
		'nodes'
	],
	#category : #'SmaCC_Runtime'
}

{ #category : #'instance creation' }
SmaCCStack class >> startingAt: anInteger [
  ^self new
     setStartingState: anInteger;
     yourself
]

{ #category : #comparing }
SmaCCStack >> = anObject [
	^ self == anObject
		or:
			[ self class = anObject class and: [ self stateStack = anObject stateStack and: [ self nodeStack = anObject nodeStack ] ] ]
]

{ #category : #copying }
SmaCCStack >> copyStackObject: anObject [
	(anObject isKindOf: String) ifTrue: [ ^ anObject ].
	(anObject isKindOf: Collection) ifTrue: [ 
		^ anObject collect: [ :each | self copyStackObject: each ] ].
	(anObject isKindOf: SmaCCParseNode) ifTrue: [ ^ anObject copy ].
	^ anObject
]

{ #category : #'parser actions' }
SmaCCStack >> dismissStackTopForErrorRecovery: anInteger [
	| stackContents |
	stackContents := Array new: anInteger.
	anInteger to: 1 by: -1 do: [ :i | 
		states removeLast.
		stackContents at: i put: nodes removeLast ].
	^ stackContents
]

{ #category : #copying }
SmaCCStack >> fullCopy [
	| copy |
	copy := self copy.
	nodes keysAndValuesDo: [ :i :each | copy nodeStack at: i put: (self copyStackObject: each) ].
	^ copy
]

{ #category : #comparing }
SmaCCStack >> hash [
	^ self stateStack hash
]

{ #category : #testing }
SmaCCStack >> includesObject: anObject [
	^ nodes includes: anObject
]

{ #category : #'initialize-release' }
SmaCCStack >> initialize [
	super initialize.
	nodes := OrderedCollection new.
	states := OrderedCollection new
]

{ #category : #testing }
SmaCCStack >> isAtStartingState [
	^ nodes isEmpty
]

{ #category : #accessing }
SmaCCStack >> nodeStack [
	^ nodes
]

{ #category : #accessing }
SmaCCStack >> nodeStack: aCollection [
	nodes := aCollection
]

{ #category : #copying }
SmaCCStack >> postCopy [
	super postCopy.
	states := states copy.
	nodes := nodes copy
]

{ #category : #'parser actions' }
SmaCCStack >> reduce: anInteger do: aBlock [
	| items |
	items := Array new: anInteger.
	anInteger
		to: 1
		by: -1
		do:
			[ :i | 
			items at: i put: nodes removeLast.
			states removeLast ].
	aBlock cull: items cull: false
]

{ #category : #accessing }
SmaCCStack >> result [
  ^nodes first
]

{ #category : #'parser actions' }
SmaCCStack >> runDeferredActionsFor: aSmaCCParser [
	nodes keysAndValuesDo: [ :i :each | nodes at: i put: (each performOnSmaCCParser: aSmaCCParser) ]
]

{ #category : #'parser actions' }
SmaCCStack >> setStartingState: startingState [
  states := OrderedCollection with: startingState
]

{ #category : #'parser actions' }
SmaCCStack >> shift: anObject to: anInteger [
	states addLast: anInteger.
	nodes addLast: anObject
]

{ #category : #accessing }
SmaCCStack >> size [
	^nodes size
]

{ #category : #accessing }
SmaCCStack >> stateStack [
	^ states
]

{ #category : #accessing }
SmaCCStack >> stateStack: aCollection [
	states := aCollection
]

{ #category : #accessing }
SmaCCStack >> topNode [
	^self nodeStack last
]

{ #category : #accessing }
SmaCCStack >> topState [
	^self stateStack last
]
