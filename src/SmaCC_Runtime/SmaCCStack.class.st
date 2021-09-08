Class {
	#name : 'SmaCCStack',
	#superclass : 'Object',
	#instVars : [
		'tops'
	],
	#category : 'SmaCC_Runtime'
}

{ #category : 'instance creation' }
SmaCCStack class >> startingAt: anInteger [
  ^self new
     setStartingState: anInteger;
     yourself
]

{ #category : 'comparing' }
SmaCCStack >> = anObject [
	^ self == anObject
		or:
			[ self class = anObject class and: [ self stateStack = anObject stateStack and: [ self nodeStack = anObject nodeStack ] ] ]
]

{ #category : 'copying' }
SmaCCStack >> copyStackObject: anObject [
	(anObject isKindOf: String) ifTrue: [ ^ anObject ].
	(anObject isKindOf: Collection) ifTrue: [ 
		^ anObject collect: [ :each | self copyStackObject: each ] ].
	(anObject isKindOf: SmaCCParseNode) ifTrue: [ ^ anObject copy ].
	^ anObject
]

{ #category : 'parser actions' }
SmaCCStack >> dismissStackTopForErrorRecovery: anInteger [
	| stackContents |
	stackContents := OrderedCollection new.
	anInteger
		timesRepeat:
			[ | nextNode |
			stackContents addFirst: tops first node.
			nextNode := tops first next.
			tops notEmpty ifTrue: [tops removeFirst].
			tops add: nextNode ].
	^ stackContents asArray
]

{ #category : 'accessing' }
SmaCCStack >> drawGraphOn: aView [
	<gtView>
	
	^ (aView mondrian)
		title: 'Graph';
		painting: [ :m | self paintWith: m ]
]

{ #category : 'copying' }
SmaCCStack >> fullCopy [
	| copy |
	copy := self copy.
"	nodes keysAndValuesDo: [ :i :each | copy nodeStack at: i put: (self copyStackObject: each) ]."
	^ copy
]

{ #category : 'comparing' }
SmaCCStack >> hash [
	^ self stateStack hash
]

{ #category : 'testing' }
SmaCCStack >> includesObject: anObject [
	self stackDo: [ :each | each = anObject ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'initialize-release' }
SmaCCStack >> initialize [
	super initialize.
	tops := SortedCollection new
]

{ #category : 'testing' }
SmaCCStack >> isAtStartingState [
	^ tops isEmpty
]

{ #category : 'accessing' }
SmaCCStack >> nodeStack [
	| aCollection |
	aCollection := OrderedCollection new.
	self stackDo: [ :each | aCollection addFirst: each ].
	aCollection isEmpty ifFalse: [aCollection removeFirst].
	^ aCollection
]

{ #category : 'accessing' }
SmaCCStack >> nodeStack: anObject [
	"Kind of a hack until this refactoring is finished"

	| topState |
	topState := tops first ifNil: [ 1 ] ifNotNil: [ tops first state ].
	tops removeFirst.
	tops
		add:
			(SmaCCStackNode
				state: 1
				node: anObject
				next: nil)
]

{ #category : 'accessing' }
SmaCCStack >> paintWith: m [

	| stackNodes n |
	stackNodes := OrderedCollection new.
	n := tops.
	[ n notNil ] whileTrue: [ 
		stackNodes addFirst: n.
		n := n next ].
	m nodes
		stencil: [ :c | 
			BlTextElement new text: c state printString asRopedText "glamorousRegularFont" ];
		with: stackNodes.
	m edges
		fromNearestCircle;
		toNearestCircle;
		stencil: [ :d | 
			BlParabollaArcElement new
				when: BlClickEvent do: [ :e | 
					e consumed: true.
					e target phlow spawnObject: d node ];
				curvatureFraction: 0.2;
				border: (BlBorder paint: (Color gray alpha: 0.2) width: 1);
				toHead: (BlArrowheadSimpleArrow new border: (BlBorder builder
								  paint: (Color gray alpha: 0.2);
								  width: 1;
								  build)) ];
		connect: stackNodes
		from: [ :each | each ]
		to: [ :each | each next ].
	m layout tree
]

{ #category : 'copying' }
SmaCCStack >> postCopy [
	super postCopy.
	tops := tops collect: [ :each | each copy ]
]

{ #category : 'parser actions' }
SmaCCStack >> reduce: anInteger do: aBlock [
	| items |
	items := Array new: anInteger.
	anInteger
		to: 1
		by: -1
		do:
			[ :i | 
			| nextNode |
			items at: i put: tops first node.
			nextNode := tops first next.
			tops removeFirst.
			tops add: nextNode ].
	aBlock cull: items cull: false
]

{ #category : 'accessing' }
SmaCCStack >> replaceNodes: aCollection [
	| stackNode |
	stackNode := tops first.
	aCollection
		reverseDo:
			[ :each | 
			stackNode ifNil: [ ^ self ].
			stackNode node: each.
			stackNode := stackNode next ]
]

{ #category : 'accessing' }
SmaCCStack >> result [
  ^tops first node
]

{ #category : 'parser actions' }
SmaCCStack >> runDeferredActionsFor: aSmaCCParser [
	| stacknode |
	stacknode := tops first.
	[ stacknode isNil ]
		whileFalse:
			[ stacknode node: (stacknode node performOnSmaCCParser: aSmaCCParser).
			stacknode := stacknode next ]
]

{ #category : 'private' }
SmaCCStack >> searchStackFor: searchItems [
	| scannerState i stackItem |
	i := self size - 1.
	scannerState := nil.
	[ i > 0 and: [ scannerState isNil ] ]
		whileTrue:
			[ stackItem := self nodeStack at: i.
			(searchItems includes: stackItem) ifTrue: [ scannerState := stackItem ].
			i := i - 1 ].
	^ scannerState
]

{ #category : 'parser actions' }
SmaCCStack >> setStartingState: startingState [
	tops
		add:
			(SmaCCStackNode
				state: startingState
				node: nil
				next: nil)
]

{ #category : 'parser actions' }
SmaCCStack >> shift: anObject to: anInteger [
	| newNode oldTop |
	oldTop := tops isEmpty ifTrue: [ nil ] ifFalse: [ tops removeFirst ].
	newNode := SmaCCStackNode
		state: anInteger
		node: anObject
		next: oldTop.
	tops add: newNode
]

{ #category : 'accessing' }
SmaCCStack >> size [
	| count node |
	count := 0.
	node := tops first.
	[ node isNil ]
		whileFalse:
			[ count := count + 1.
			node := node next ].
	^ count
]

{ #category : 'enumerating' }
SmaCCStack >> stackDo: aBlock [
	| stacknode |
	tops isEmpty ifTrue: [^self].
	stacknode := tops first.
	[ stacknode isNil ]
		whileFalse:
			[ aBlock value: stacknode node.
			stacknode := stacknode next ]
]

{ #category : 'accessing' }
SmaCCStack >> stateStack [
	| aCollection |
	aCollection := OrderedCollection new.
	self stateStackDo: [ :each | aCollection addFirst: each ].
	^ aCollection
]

{ #category : 'enumerating' }
SmaCCStack >> stateStackDo: aBlock [
	| stacknode |
	tops isEmpty ifTrue: [ ^ self ].
	stacknode := tops first.
	[ stacknode isNil ]
		whileFalse:
			[ aBlock value: stacknode state.
			stacknode := stacknode next ]
]

{ #category : 'accessing' }
SmaCCStack >> topNode [
	^tops first node
]

{ #category : 'accessing' }
SmaCCStack >> topNode: anObject [
	^ tops first node: anObject
]

{ #category : 'accessing' }
SmaCCStack >> topState [
	^tops first state
]
