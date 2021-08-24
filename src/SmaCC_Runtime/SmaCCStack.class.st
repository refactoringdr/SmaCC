Class {
	#name : #SmaCCStack,
	#superclass : #Object,
	#instVars : [
		'top'
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
	stackContents := OrderedCollection new.
	anInteger
		timesRepeat:
			[ stackContents addFirst: top node.
			top := top next ].
	^ stackContents asArray
]

{ #category : #copying }
SmaCCStack >> fullCopy [
	| copy |
	copy := self copy.
"	nodes keysAndValuesDo: [ :i :each | copy nodeStack at: i put: (self copyStackObject: each) ]."
	^ copy
]

{ #category : #comparing }
SmaCCStack >> hash [
	^ self stateStack hash
]

{ #category : #testing }
SmaCCStack >> includesObject: anObject [
	self stackDo: [ :each | each = anObject ifTrue: [ ^ true ] ].
	^ false
]

{ #category : #'initialize-release' }
SmaCCStack >> initialize [
	super initialize.
	top := nil
]

{ #category : #testing }
SmaCCStack >> isAtStartingState [
	^ top isNil
]

{ #category : #accessing }
SmaCCStack >> nodeStack [
	| aCollection |
	aCollection := OrderedCollection new.
	self stackDo: [ :each | aCollection addFirst: each ].
	^ aCollection
]

{ #category : #accessing }
SmaCCStack >> nodeStack: anObject [
	"Kind of a hack until this refactoring is finished"
	top := SmaCCStackNode state: 1 node: anObject next: nil.
]

{ #category : #copying }
SmaCCStack >> postCopy [
	super postCopy.
	top := top copy
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
			items at: i put: top node.
			top := top next ].
	aBlock cull: items cull: false
]

{ #category : #accessing }
SmaCCStack >> result [
  ^top node
]

{ #category : #'parser actions' }
SmaCCStack >> runDeferredActionsFor: aSmaCCParser [
	| stacknode |
	stacknode := top.
	[ stacknode isNil ]
		whileFalse:
			[ stacknode node: (stacknode node performOnSmaCCParser: aSmaCCParser).
			stacknode := stacknode next ]
]

{ #category : #private }
SmaCCStack >> searchStackFor: searchItems [
	| scannerState i stackItem |
	i := self size.
	scannerState := nil.
	[ i > 0 and: [ scannerState isNil ] ]
		whileTrue:
			[ stackItem := self nodeStack at: i.
			(searchItems includes: stackItem) ifTrue: [ scannerState := stackItem ].
			i := i - 1 ].
	^ scannerState
]

{ #category : #'parser actions' }
SmaCCStack >> setStartingState: startingState [
  top := SmaCCStackNode state: startingState node: nil next: nil
]

{ #category : #'parser actions' }
SmaCCStack >> shift: anObject to: anInteger [
	top := SmaCCStackNode
		state: anInteger
		node: anObject
		next: top
]

{ #category : #accessing }
SmaCCStack >> size [
	| count node |
	count := 0.
	node := top.
	[ node isNil ]
		whileFalse:
			[ count := count + 1.
			node := node next ].
	^ count
]

{ #category : #enumerating }
SmaCCStack >> stackDo: aBlock [
	| stacknode |
	stacknode := top.
	[ stacknode isNil ]
		whileFalse:
			[ aBlock value: stacknode node.
			stacknode := stacknode next ]
]

{ #category : #accessing }
SmaCCStack >> stateStack [
	| aCollection |
	aCollection := OrderedCollection new.
	self stateStackDo: [ :each | aCollection addFirst: each ].
	^ aCollection
]

{ #category : #enumerating }
SmaCCStack >> stateStackDo: aBlock [
	| stacknode |
	stacknode := top.
	[ stacknode isNil ]
		whileFalse:
			[ aBlock value: stacknode state.
			stacknode := stacknode next ]
]

{ #category : #accessing }
SmaCCStack >> topNode [
	^top node
]

{ #category : #accessing }
SmaCCStack >> topNode: anObject [
	^top node: anObject
]

{ #category : #accessing }
SmaCCStack >> topState [
	^top state
]
