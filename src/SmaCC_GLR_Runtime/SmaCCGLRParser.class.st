"
SmaCCGLRParser is an abstract superclass for all GLR generated parsers in SmaCC.

Instance Variables:
	currentState	<SmaCCParserState>	the current parse that we are trying
	lastPosition	<Integer>	the starting location of the scanner before calling getNextToken
	lastState	<Symbol>	the state of the scanner before calling getNextToken
	lastToken	<SmaCCToken>	the token returned from getNextToken (if the lastState and lastToken are the same as the current token, then this value is returned without scanning anything)
	nextScannerPosition	<Integer>	the ending location of the scanner after calling getNextToken
	nextScannerState	<Symbol>	the ending state of the scanner after calling getNextToken
	parseAll	<Boolean>	should we return a collection of all potential parses or just one
	states	<SequenceableCollection of: SmaCCParserState>	the current list of valid parses
	tryAllStates	<Boolean>	should we try to parse starting from any state instead of the starting state

"
Class {
	#name : #SmaCCGLRParser,
	#superclass : #SmaCCParser,
	#instVars : [
		'states',
		'parseAll',
		'currentState',
		'tryAllStates',
		'lastToken',
		'lastState',
		'nextScannerState',
		'parseAsEmbedded'
	],
	#classInstVars : [
		'cachedTrees',
		'maxParallelParses'
	],
	#category : #'SmaCC_GLR_Runtime'
}

{ #category : #accessing }
SmaCCGLRParser class >> cachedTrees [
	^ cachedTrees ifNil: [ cachedTrees := Dictionary new ]
]

{ #category : #accessing }
SmaCCGLRParser class >> maxParallelParses [
	^ maxParallelParses ifNil: [ maxParallelParses := SmallInteger maxVal ]
]

{ #category : #accessing }
SmaCCGLRParser class >> maxParallelParses: anInteger [
	maxParallelParses := anInteger
]

{ #category : #parsing }
SmaCCGLRParser class >> parseAll: aString startingAt: anInteger [
	| parser results |
	parser := self
		createParserOnStream: (ReadStream on: aString)
		startingAt: anInteger.
	parser parseAll: true.
	results := parser parse.
	results
		do: [ :each | 
			(each isKindOf: SmaCCParseNode)
				ifTrue: [ each completeSource: aString ] ].
	^ results
]

{ #category : #parsing }
SmaCCGLRParser class >> parseAllPossibleStates: aString [
	"Returns all possible parse nodes that can be created from aString starting from any place in the parser."

	| parser results |
	parser := self on: (ReadStream on: aString).
	parser
		parseAll: true;
		setAllStartingStates.
	results := parser parse asSet asOrderedCollection.
	results
		do: [ :each | 
			(each isKindOf: SmaCCParseNode)
				ifTrue: [ each completeSource: aString ] ].
	^ results
]

{ #category : #parsing }
SmaCCGLRParser class >> parseAndCacheAll: aString startingAt: anInteger [
	^ (self cachedTrees at: (Array with: aString with: anInteger) ifAbsentPut: [ self parseAll: aString startingAt: anInteger ]) copy
]

{ #category : #parsing }
SmaCCGLRParser class >> parseAndCacheAllPossibleStates: aString [
	^ (self cachedTrees at: (Array with: aString with: nil) ifAbsentPut: [ self parseAllPossibleStates: aString ]) copy
]

{ #category : #parsing }
SmaCCGLRParser class >> parseEmbeddedStream: aStream [
	^ self
		parseEmbeddedStream: aStream
		startingAt: self defaultStartingState
]

{ #category : #parsing }
SmaCCGLRParser class >> parseEmbeddedStream: aStream startingAt: anInteger [
	| parser |
	parser := self createParserOnStream: aStream startingAt: anInteger.
	parser enableEmbeddedParsing.
	^ parser parse
]

{ #category : #accessing }
SmaCCGLRParser class >> resetCaches [
	super resetCaches.
	cachedTrees := nil
]

{ #category : #private }
SmaCCGLRParser >> actionsDo: aBlock [
	| row actionBlock |
	actionBlock := [ :action | 
	(self isAmbiguous: action)
		ifTrue: [ | ambiguous |
			ambiguous := OrderedCollection new.
			self ambiguousTransitionsAt: (action bitShift: -2) into: ambiguous.
			ambiguous do: aBlock ]
		ifFalse: [ aBlock value: action ] ].
	row := self transitionTable at: self currentState.
	(row at: 1) == 0
		ifTrue: [ actionBlock value: ((row at: 2) bitShift: 8) + (row at: 3) ]
		ifFalse: [ 2 to: row size by: 4 do: [ :i | actionBlock value: ((row at: i) bitShift: 8) + (row at: i + 1) ] ]
]

{ #category : #private }
SmaCCGLRParser >> actionsForCurrentToken [
	| actions |
	actions := OrderedCollection new: 1.
	self tryAllTokens
		ifTrue: [ currentToken ids
				do: [ :each | 
					self addActionsFor: each to: actions.
					(actions notEmpty and: [ self useAllTokenIds not ])
						ifTrue: [ ^ actions ] ] ]
		ifFalse: [ self addActionsFor: currentToken ids first to: actions ].
	^ actions
]

{ #category : #'error handling' }
SmaCCGLRParser >> actionsForState: stateIndex and: aSymbolIndex [
	| actions |
	actions := OrderedCollection new.
	self addActionsForState: stateIndex symbol: aSymbolIndex to: actions.
	^ actions
]

{ #category : #private }
SmaCCGLRParser >> addAction: action to: anOrderedCollection [
	(anOrderedCollection includes: action)
		ifTrue: [ ^ self ].
	anOrderedCollection add: action
]

{ #category : #private }
SmaCCGLRParser >> addActionsFor: anInteger to: anOrderedCollection [
	| state |
	state := self currentState.
	self
		addActionsForState: state
		symbol: anInteger
		to: anOrderedCollection
]

{ #category : #private }
SmaCCGLRParser >> addActionsForState: state symbol: anInteger to: anOrderedCollection [
	| action |
	action := self actionForState: state and: anInteger.
	action = self errorAction
		ifTrue: [ ^ self ].
	(self isAmbiguous: action)
		ifTrue: [ self
				ambiguousTransitionsAt: (action bitShift: -2)
				into: anOrderedCollection ]
		ifFalse: [ self addAction: action to: anOrderedCollection ]
]

{ #category : #private }
SmaCCGLRParser >> addEmbeddedActions [
	| i |
	i := states size.
	[ i > 0 ]
		whileTrue: [ self tryEmbededAcceptFor: (states at: i).
			i := i - 1 ]
]

{ #category : #private }
SmaCCGLRParser >> alwaysPerformReduceAction [
	^ false
]

{ #category : #private }
SmaCCGLRParser >> ambiguousTransitionsAt: anIndex into: anOrderedCollection [
	| ambiguousTransitions |
	ambiguousTransitions := self ambiguousTransitions at: anIndex.
	1 to: ambiguousTransitions size by: 2 do:
		[ :i | 
		self
			addAction:
				((ambiguousTransitions at: i) bitShift: 8)
					+ (ambiguousTransitions at: i + 1)
			to: anOrderedCollection ]
]

{ #category : #private }
SmaCCGLRParser >> copyStackObject: anObject [
	(anObject isKindOf: String) ifTrue: [^anObject].
	(anObject isKindOf: Collection) ifTrue: [^anObject collect: [:each | self copyStackObject: each]].
	(anObject isKindOf: SmaCCParseNode) ifTrue: [^anObject copy].
	^anObject
]

{ #category : #private }
SmaCCGLRParser >> currentGLRState [
	^ currentState
]

{ #category : #private }
SmaCCGLRParser >> duplicateState [
	| state |
	(parseAsEmbedded not and: [states size >= self class maxParallelParses]) ifTrue: [ SmaCCTooAmbiguousNotification signal ].
	parseAll ifTrue: [nodeStack := nodeStack collect: [:each | self copyStackObject: each]] ifFalse: [nodeStack := nodeStack copy].
	stateStack := stateStack copy.
	state := currentState copy.
	state stateStack: stateStack nodeStack: nodeStack.
	state scannerState: scanner currentState.
	states add: state.
	^state
]

{ #category : #'initialize-release' }
SmaCCGLRParser >> enableEmbeddedParsing [
	parseAsEmbedded := true
]

{ #category : #private }
SmaCCGLRParser >> fixObject: anObject [
	| result |
	result := anObject performOnSmaCCParser: self.
	(result isKindOf: SmaCCParseNode)
		ifTrue: [ result fixParentPointers ].
	^ result
]

{ #category : #private }
SmaCCGLRParser >> getAcceptedObject [
	^ parseAsEmbedded
		ifTrue: [ | state |
			state := (states
				asSortedCollection: [ :a :b | a scannerState position > b scannerState position ])
				first.
			self restoreState: state.
			state nodeStack first ]
		ifFalse: [ states first nodeStack first ]
]

{ #category : #private }
SmaCCGLRParser >> getNextToken [
	currentToken isNil
		ifFalse: [ ^ self ].
	lastState = currentState scannerState
		ifTrue: [ currentToken := lastToken.
			scanner restoreState: nextScannerState.
			currentState scannerState: nextScannerState ]
		ifFalse: [ lastState := currentState scannerState.
			scanner restoreState: currentState scannerState.
			lastToken := currentToken := scanner next.
			nextScannerState := scanner currentState ].
	currentState scannerState: nextScannerState
]

{ #category : #parsing }
SmaCCGLRParser >> handleEmbeddedError: aSmaCCParserError [
	| parser errorNode |
	parser := aSmaCCParserError parser.
	errorNode := SmaCCErrorNode new
		stackContents: parser nodeStack copy;
		dismissedTokens: #().
	self position: parser currentToken startPosition - 1.
	errorNode
		errorToken:
			(SmaCCToken
				value: ''
				start: parser currentToken startPosition
				ids: #()).
	^ errorNode
]

{ #category : #private }
SmaCCGLRParser >> initialParserState [
	| state |
	state := SmaCCParserState
		stateStack: stateStack
		nodeStack: nodeStack
		scannerState: scanner currentState.
	^ state
]

{ #category : #'initialize-release' }
SmaCCGLRParser >> initialize [
	super initialize.
	states := OrderedCollection new.
	parseAll := false.
	tryAllStates := false.
	parseAsEmbedded := false
]

{ #category : #private }
SmaCCGLRParser >> isAmbiguous: action [
	^ (action bitAnd: self actionMask) = 2r11
]

{ #category : #private }
SmaCCGLRParser >> killState [
	| index |
	index := states identityIndexOf: currentState ifAbsent: [ ^ false ].
	states size = 1
		ifTrue: [ ^ self handleError: 0 ].
	states removeAt: index.
	(states size = 1 and: [ parseAll not ])
		ifTrue: [ states first runDeferredActionsFor: self ].
	^ false
]

{ #category : #private }
SmaCCGLRParser >> mergeStates [
	| i j state otherStates otherState |
	i := 1.
	[ i < states size ]
		whileTrue:
			[ state := states at: i.
			otherStates := OrderedCollection new.
			j := i := i + 1.
			[ j <= states size ]
				whileTrue:
					[ otherState := states at: j.
					(parseAll
						ifTrue: [ state = otherState ]
						ifFalse: [ state canBeMergedWith: otherState ])
						ifTrue: [ otherStates add: otherState.
							states removeAt: j ]
						ifFalse: [ j := j + 1 ] ].
			(parseAll not and: [ otherStates notEmpty ])
				ifTrue: [ state mergeWith: otherStates ] ]
]

{ #category : #accessing }
SmaCCGLRParser >> parseAll: aBoolean [
	parseAll := aBoolean
]

{ #category : #private }
SmaCCGLRParser >> parseCurrentToken [
	| actions action isAccept |
	[ actions := self actionsForCurrentToken.
	actions isEmpty
		ifTrue: [ isAccept := false.
			self killState
				ifFalse: [ ^ currentToken := nil ] ]
		ifFalse:
			[ 2 to: actions size do: [ :i | self splitWithAction: (actions at: i) ].
			action := actions first.
			isAccept := action = self acceptAction.
			isAccept
				ifFalse: [ self performAction: action ] ].
	isAccept or: [ currentToken isNil ] ] whileFalse.
	action = self acceptAction
		ifTrue: [ currentState markAccepted ]
]

{ #category : #private }
SmaCCGLRParser >> performParsingLoop [
	| result i |
	self setStartingStatesIfNone.
	[ i := states size.
	[ i > 0 ]
		whileTrue: [ (states at: i) isAccepted
				ifFalse: [ [ currentToken := nil.
					self restoreState: (states at: i).
					self getNextToken.
					self performParsingStep ]
						on: SmaCCTooAmbiguousNotification
						do: [ :ex | 
							self trimParallelParses.
							i := i min: states size + 1 ] ].
			i := i - 1 ].
	self mergeStates.
	parseAsEmbedded
		ifTrue: [ self addEmbeddedActions ].
	states anySatisfy: [ :each | each isAccepted not ] ] whileTrue.
	self checkForErrors.
	result := parseAll
		ifTrue: [ states collect: [ :each | self fixObject: each nodeStack first ] ]
		ifFalse: [ self fixObject: self getAcceptedObject ].
	nodeStack := OrderedCollection with: result
]

{ #category : #private }
SmaCCGLRParser >> performParsingStep [
	currentState isAccepted
		ifTrue: [ ^ self ].
	self restoreState: currentState.
	(tryAllStates and: [ self isEOFToken ])
		ifTrue: [ ^ self processEOFToken ].
	currentToken isPattern
		ifTrue: [ ^ self splitForPatternToken ].
	self parseCurrentToken
]

{ #category : #private }
SmaCCGLRParser >> performReduceEntry: entryArray with: items [
	^ (states size = 1
		or: [ parseAll or: [ entryArray at: 5 ifAbsent: [ false ] ] ])
		ifTrue:
			[ 1 to: items size do: [ :i | items at: i put: ((items at: i) performOnSmaCCParser: self) ].
			super performReduceEntry: entryArray with: items ]
		ifFalse: [ SmaCCDeferredReduceAction entry: entryArray arguments: items ]
]

{ #category : #private }
SmaCCGLRParser >> popNodeStack [
	| result |
	result := nodeStack removeLast.
	(self alwaysPerformReduceAction and: [ states size > 1 ])
		ifTrue: [ result := self copyStackObject: result ].
	^ result
]

{ #category : #private }
SmaCCGLRParser >> position: anInteger [
	super position: anInteger.
	currentState scannerState: scanner currentState
]

{ #category : #private }
SmaCCGLRParser >> processEOFToken [
	| originalState performed eofToken |
	currentState isAccepted
		ifTrue: [ ^ self ].
	eofToken := currentToken.
	originalState := currentState.
	performed := Set new.
	self
		reduceActionsDo: [ :each | 
			(performed includes: each)
				ifFalse: [ performed add: each.
					self restoreState: self duplicateState.
					currentToken := eofToken.
					self performAction: each.
					(nodeStack size = 1 and: [ nodeStack first isKindOf: SmaCCParseNode ])
						ifTrue: [ currentState markAccepted ]
						ifFalse: [ (originalState stateStack size <= stateStack size and: [ originalState stateStack last == stateStack last ])
								ifTrue: [ self killState ]
								ifFalse: [ self processEOFToken ] ].
					self restoreState: originalState ] ].
	currentToken := eofToken.
	(nodeStack size = 1 and: [ nodeStack first isKindOf: SmaCCParseNode ])
		ifTrue: [ currentState markAccepted ]
		ifFalse: [ self killState ]
]

{ #category : #private }
SmaCCGLRParser >> reduce: anInteger [
	| reduceEntry items size |
	reduceEntry := self reduceTable at: anInteger.
	items := Array new: (size := reduceEntry at: 2).
	nodeStack size < size
		ifTrue: [ self killState.
			^ currentToken := nil ].
	size to: 1 by: -1 do: [ :i | 
		items at: i put: self popNodeStack.
		stateStack removeLast ].
	nodeStack addLast: (self performReduceEntry: reduceEntry with: items).
	stateStack
		addLast: ((self actionFor: (reduceEntry at: 1)) bitShift: -2)
]

{ #category : #private }
SmaCCGLRParser >> reduceActionsDo: aBlock [
	self
		actionsDo: [ :each | 
			(each bitAnd: self actionMask) = self reduceAction
				ifTrue: [ aBlock value: each ] ]
]

{ #category : #private }
SmaCCGLRParser >> restoreState: aSmaCCParserState [
	currentState := aSmaCCParserState.
	nodeStack := aSmaCCParserState nodeStack.
	stateStack := aSmaCCParserState stateStack.
	scanner restoreState: currentState scannerState
]

{ #category : #private }
SmaCCGLRParser >> scope: aSymbol [
	super scope: aSymbol.
	currentState notNil
		ifTrue: [ currentState scannerState: scanner currentState ]
]

{ #category : #accessing }
SmaCCGLRParser >> setAllStartingStates [
	tryAllStates := true.
	self statesThatShift
		do:
			[ :each | 
			states
				add:
					(SmaCCParserState
						stateStack: (OrderedCollection with: each)
						nodeStack: OrderedCollection new
						scannerState: scanner currentState) ]
]

{ #category : #private }
SmaCCGLRParser >> setStartingStatesIfNone [
	states isEmpty ifTrue: [ states add: self initialParserState ].
	parseAsEmbedded ifTrue: [ self addEmbeddedActions ]
]

{ #category : #parsing }
SmaCCGLRParser >> spawnParser: aGLRParserClass startingAt: anInteger [
	^ [ super spawnParser: aGLRParserClass startingAt: anInteger ]
		on: SmaCCParserError
		do: [ :ex | 
			errorHandler handlesErrors
				ifFalse: [ ex signal ].
			ex return: (self handleEmbeddedError: ex) ]
]

{ #category : #private }
SmaCCGLRParser >> splitForPatternToken [
	| token patternNode performedActions nodeClass |
	performedActions := Set new.
	token := currentToken copy.
	token ids: OrderedCollection new.
	patternNode := SmaCCPatternNode onToken: token copy.
	nodeClass := token nodeClassName
		ifNil: [ SmaCCParseNode ]
		ifNotNil: [ :name | self class environment at: name ifAbsent: [ SmaCCParseNode ] ].
	self symbolTypes
		keysAndValuesDo:
			[ :i :each | 
			| actions |
			(i ~= scanner emptySymbolTokenId and: [ i ~= scanner errorTokenId ])
				ifTrue:
					[ actions := OrderedCollection new.
					(each = #SmaCCToken
						or:
							[ each notNil
								and:
									[ ((self class environment at: each ifAbsent: [ Object ])
includesBehavior: nodeClass) or: [ nodeClass includesBehavior: (self
class environment at: each ifAbsent: [ self class ]) ] ] ])
						ifTrue:
							[ self addActionsFor: i to: actions.
							actions
								do:
									[ :action | 
									(performedActions includes: action)
										ifFalse:
											[ performedActions add: action.
											each = #SmaCCToken
												ifTrue:
													[ token ids add: i.
													((action bitAnd: self actionMask) = self reduceAction
														or: [ token isToken ])
														ifTrue: [ currentToken := token.
															self splitWithAction: action ] ]
												ifFalse:
													[ token isNode
														ifTrue:
															[ currentToken := nil.
															self duplicateState.
															stateStack addLast: (action bitShift: -2).
															nodeStack addLast: patternNode.
															self restoreState: currentState ] ] ] ] ] ] ].
	self killState.
	currentToken := nil
]

{ #category : #private }
SmaCCGLRParser >> splitWithAction: anInteger [
	| previousToken previousState |
	previousState := currentState.
	previousToken := currentToken.
	[ currentState := self duplicateState.
	self performAction: anInteger.
	currentToken notNil
		ifTrue: [ self performParsingStep ] ]
		ensure: [ self restoreState: previousState.
			currentToken := previousToken ]
]

{ #category : #private }
SmaCCGLRParser >> states [
	^states
]

{ #category : #private }
SmaCCGLRParser >> statesThatShift [
	^ (1 to: self transitionTable size)
		select:
			[ :each | 
			(1 to: self symbolTypes size)
				anySatisfy:
					[ :i | 
					| actions |
					actions := OrderedCollection new.
					self addActionsForState: each symbol: i to: actions.
					actions
						anySatisfy: [ :action | (action bitAnd: self actionMask) = self shiftAction ] ] ]
]

{ #category : #private }
SmaCCGLRParser >> trimParallelParses [
	"Since we don't implement the whole GLR algorithm, for highly ambiguous grammars we can have exponential parses. When we grow too large, we indiscriminately delete some."

	| newCount |
	newCount := (self class maxParallelParses bitShift: -2) max: 1.
	states := states copyFrom: 1 to: newCount
]

{ #category : #private }
SmaCCGLRParser >> tryEmbededAcceptFor: state [
	| actions newState |
	state isAccepted
		ifTrue: [ ^ self ].
	actions := OrderedCollection new.
	self
		addActionsForState: state stateStack last
		symbol: scanner eofTokenId first
		to: actions.
	(actions includes: self acceptAction)
		ifTrue: [ ^ state markAccepted ].
	actions
		do: [ :action | 
			self restoreState: state.
			newState := currentState := self duplicateState.
			currentToken := SmaCCToken
				value: ''
				start: currentState scannerState position
				ids: scanner eofTokenId.
			self performAction: action.
			self tryEmbededAcceptFor: currentState.
			newState isAccepted
				ifFalse: [ currentState := newState.
					self killState ] ]
]

{ #category : #testing }
SmaCCGLRParser >> useAllTokenIds [
	^ true
]
