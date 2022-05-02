Class {
	#name : #SmaCCRustCodeGenerator,
	#superclass : #SmaCCTypedLanguageCodeGenerator,
	#category : #'SmaCC_Typed_Code_Generation'
}

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> codeTemplatesArray [
	^ super codeTemplatesArray, #(
			#(#addAllSendTo:with: 'AddAllToCollection(<1s>,<2s>)')
			#(#addSendTo:with: '<1s>.Add(<2s>)')
			#(#arrayType 'object []')
			#(#assignArray:index:to: '<1s>[<2p>] = <3s>')
			#(#at:index: '<1s>[<2p>]')
			#(#booleanType 'bool')
			#(#collectionType 'IList')
			#(#compareEqual:to: 'CompareObjects(<1s>, <2s>)')
			#(#copy:inContext:onlyNodes: 'CopyInContext(<1s>, <2s>)')
			#(#copyNode: 'Copy(<1s>)')
			#(#copyNodeCollection: 'Copy(<1s>)')
			#(#dictionaryType 'IDictionary')
			#(#endDoWhileLoopWithClause: ' if !(<1s>) { break; } }')
			#(#hashFor: '<1s>.GetHashCode()')
			#(#isKindOfTest:class: 'if (<1s> is <2s>) {')
			#(#iterateObjects:name: 'foreach (object <2s> in <1s>) {')
			#(#newArrayOfSize: 'new object[<1p>]')
			#(#newCollectionOfSize: 'new ArrayList(<1p>)')
			#(#newDeclaration '')
			#(#newUnsignedShortArray 'new usize[] {')
			#(#newUnsignedShortArrayArray 'new usize[][] {')
			#(#nodeCollectionType 'IList')
			#(#objectType 'object')
			#(#override '')
			#(#parentName 'Parent')
			#(#protected '')
			#(#public 'pub ')
			#(#readerType '&''a str ')
			#(#reduceActionArrayType 'ReduceAction[]') 
			#(#reduceActionLiteralStart 'new ReduceAction[] {') 
			#(#startDoWhileLoop 'loop {')
			#(#startIfWithClause: 'if <1s> {')
			#(#stringType '&str') 
			#(#unsignedShort 'usize') 
			#(#unsignedShortArray 'usize[]') 
			#(#unsignedShortArrayArray 'usize[][]') 
			#(#uppercaseString: '<1s>.to_uppercase()')
			#(#virtual ''))
]

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> parseSourceSelector [
	^ #canParseSmalltalk:
]

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> typeName [
	^ #Rust
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> acceptCharacterEdge: aSmaCCCharacterEdge seen: aCollection [
	| stream |
	stream := WriteStream with: String new.
	aSmaCCCharacterEdge transitionObjects size + aCollection size
		> SmaCCGrammar maximumCharacterValue
		ifTrue: [ ^ self trueValue ].
	aSmaCCCharacterEdge transitionObjects size
		= SmaCCGrammar maximumCharacterValue
		ifTrue: [ self
				outputInvertedMatchFor: aSmaCCCharacterEdge
				on: stream ]
		ifFalse:
			[ self
				outputMatchFor: aSmaCCCharacterEdge
				seen: aCollection
				on: stream ].
	^ stream contents
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> acceptStateEdge: aSmaCCStateEdge [
	| stream |
	stream := self outputStreamClass on: String new.
	aSmaCCStateEdge transitionObjects
		do:
			[ :each | 
			stream
				nextPutAll: 'this.state == Some("';
				nextPutAll: each;
				nextPutAll: '")' ]
		separatedBy: [ stream nextPutAll: ' || ' ].
	^ stream contents
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> asStatement: methodMap forNode: aSmaCCNode lastNeedsReturn: aBoolean [
	| transitions seen | 
	aSmaCCNode hasSimpleLoop ifTrue: [ self nextPutLine: self startDoWhileLoop ].
	self writeMatchingCodeFor: aSmaCCNode.
	transitions := self sortedTransitionsForNode: aSmaCCNode.
	seen := (transitions notEmpty ifTrue: [ transitions first setClass ] ifFalse: [ Set ]) new.
	transitions
		do:
			[ :each | 
			each to = aSmaCCNode
				ifTrue: [ self nextPutStatement: (self endDoWhileLoopWithClause: (each dispatchTo: self seen: seen)) ]
				ifFalse:
					[ self nextPutLine: (self startIfWithClause: (each dispatchTo: self seen: seen)).
					(methodMap at: each to ifAbsent: [ nil ])
						ifNil:
							[ self
								asStatement: methodMap
								forNode: each to
								lastNeedsReturn: each ~= transitions last ]
						ifNotNil: [ :methodCall | self nextPutStatement: (self return: (self send: methodCall to: self receiverName)) ].
					self nextPutStatement: self endConditionalString ].
			seen addAll: each transitionObjects ].
	(aBoolean and: [ aSmaCCNode transitions notEmpty or: [ aSmaCCNode action isNil ] ])
		ifTrue: [ self nextPutStatement: (self return: (self send: #reportLastMatch to: self receiverName)) ]
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> camelToSnakeCase: aString [
	| result |
	result := WriteStream on: String new.
	aString
		do:
			[ :ch | 
			ch isUppercase ifTrue: [ result nextPut: $_ ].
			result nextPut: ch asLowercase ].
	^ result contents
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> compileIgnoreCaseMethods [
	self grammar ignoreCase
		ifFalse: [ ^ self ].
	self
		startPublicOverrideMethod;
		nextPutLine:
			(self
				method: #keywordFor:
				type: 'String'
				argumentName: 'aString'
				argumentType: self stringType);
		nextPutStatement: (self return: (self uppercaseString: 'aString'));
		endMethod;
		compileMethodIn: scannerClass
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> compileKeywordInitializerUsing: keywordMapDictionary [
	| method stream dataStream |
	stream := self outputStreamClass on: String new.
	stream
		nextPutAll: 'let mut map: HashMap<usize, HashMap<&str, usize>> = HashMap::new();';
		cr.
	keywordMapDictionary isEmpty
		ifFalse:
			[ 
			dataStream := WriteStream with: Array new.
			keywordMapDictionary
				keysAndValuesDo:
					[ :key :value | 
					value keys asSortedCollection
						do:
							[ :each | 
							dataStream
								nextPut:
									(Array
										with: key
										with: each
										with: (value at: each)) ] ].
			stream
				nextPutAll: 'let arr : [(usize, &str, usize, Option<&str>);';
				nextPutAll: dataStream contents size printString;
				nextPutAll: ']  = [';
				cr.
			stream
				indentWhile:
					[ dataStream contents
						do:
							[ :each | 
							stream nextPutAll: '('.
							each first storeOn: stream.
							stream
								nextPutAll: ',"';
								nextPutAll: each second;
								nextPutAll: '",'.
							each third isInteger
								ifTrue:
									[ each third storeOn: stream.
									stream nextPutAll: ',None' ]
								ifFalse:
									[ each third first storeOn: stream.
									stream nextPutAll: ',Some("' , each third second first , '")' ].
							stream nextPutAll: '),' ]
						separatedBy: [ stream cr ] ].
			stream
				nextPutAll: '];';
				cr.
			stream
				nextPutAll:
						'
for (state, word, id, scope) in arr {
	let dict = map.entry(state).or_insert(HashMap::new());
	dict.insert(word, id);
}';
				cr ].
	stream nextPutAll: 'map'.
	method := scannerClass
		compile: (self methodNameFor: 'initializeKeywordMap')
		type: 'HashMap<usize, HashMap<&''static str, usize>>'
		arguments: #()
		source: stream contents.
	(self codeStream)
		cr;
		cr.
	self
		nextPutLine:
			'lazy_static! {
	static ref KEYWORD_MAP: HashMap<usize, HashMap<&''static str, usize>> = initializeKeywordMap();
}'.
	self compileStaticIn: scannerClass
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> compileMethodIn: modelClass [
	modelClass compileMethod: self codeStream contents.
	self codeStream reset
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> compileOptimizedMethodIn: modelClass [
	self compileMethodIn: modelClass
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> compileStaticIn: modelClass [
	modelClass compileStatic: self codeStream contents.
	self codeStream reset
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> compileTokenIdMethodNamed: aString withId: symbolId [
	| name |
	name := (self camelToSnakeCase: aString , 'Id') asUppercase.
	self nextPutLine: 'pub static ' , name , ' : usize = ' , symbolId printString , ';'.
	self compileStaticIn: scannerClass
]

{ #category : #initialization }
SmaCCRustCodeGenerator >> initializeIsExpressions [
	isExpressions := Dictionary new.
	isExpressions at: '0123456789' put: 'is_ascii_digit()'.
	isExpressions at: '0123456789ABCDEFabcdef' put: 'is_ascii_hexdigit()'.
	isExpressions at: (($0 to: $9), ($A to: $Z) , ($a to: $z)) put: 'is_ascii_alphanumeric()'.
	isExpressions at: (SmaCCGrammar isExpressionMap at: #isLetter) put: 'is_alphabetic()'.
	isExpressions at: (SmaCCGrammar isExpressionMap at: #isDigit) put: 'is_numeric()'.
	isExpressions at: (SmaCCGrammar isExpressionMap at: #isAlphaNumeric) put: 'is_alphanumeric()'.	
	isExpressions at: (SmaCCGrammar isExpressionMap at: #isSeparator) put: 'is_ascii_whitespace()'.
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> keywords [
	^ "CSharpScanner keywordMap
		inject: Set new
		into:
			[ :sum :each | 
			sum
				addAll: each keys;
				yourself ]"   #()
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> method: aString type: typeString [
	^ 'fn ' , (self methodNameFor: aString) , '<''a>(this : &mut Scanner<''a>) -> ', typeString , ' {'
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> method: aString type: typeString argumentName: argumentNameString argumentType: argumentTypeString [
	^ 'fn ' , (self methodNameFor: aString) , '(' , argumentNameString , ' : ' , argumentTypeString , ') -> ' , typeString , ' {'
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> methodNameFor: selectorString [
	| name |
	#(
		#('=' 'Equals')
		#('hash' 'GetHashCode') 
		#('match:inContext:' 'MatchInContext') 
		#('matchCollection:to:inContext:' 'MatchCollectionInContext') 
		#('AcceptNode' 'AcceptNode') #('AcceptVisitor' 'AcceptVisitor') 
		#('BasicCreateToken' 'BasicCreateToken') 
		#('checkForKeyword' 'CheckForKeyword') #('Comment' 'comment') 
		#('CreateScanner' 'CreateScanner') 
		#('CreateToken(value)' 'CreateToken(value)') 
		#('processReduceAction' 'ProcessReduceAction') 
		#('RecordAndReportMatch' 'this.recordAndReportMatch') 
		#('RecordMatch(' 'this.recordMatch(') 
		#('ReduceFor' 'ReduceFor') 
		#('Step();' 'this.step()?;') 
		#('Whitespace' 'whitespace'))
		do: [ :each | each first = selectorString asString ifTrue: [ ^ each last ] ].
	name := selectorString asSymbol keywords first asString copy.
	name last = $: ifTrue: [ name := selectorString asString copyFrom: 1 to: selectorString size - 1 ].
	^ name
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> modelClass [
	^ SmaCCRustModel
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> outputClosureFor: anObject [
	self codeStream nextPutAll: (anObject isNil ifTrue: [ 'None' ] ifFalse: [ 'Some(|this| this.' , anObject , '())' ])
]

{ #category : #'compiling-scanner' }
SmaCCRustCodeGenerator >> outputGreaterThanMatch: each on: stream [
	stream nextPutAll: 'this.current_char >= '''.
	self writeCharacter: each first on: stream.
	stream nextPut: $'
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> outputInvertedMatchFor: aSmaCCCharacterEdge on: stream [
	| char |
	char := Character
		value:
			((0 to: SmaCCGrammar maximumCharacterValue)
				detect: [ :each | (aSmaCCCharacterEdge transitionObjects includes: (Character value: each)) not ]).
	stream nextPutAll: 'this.current_char != '''.
	self writeCharacter: char on: stream.
	stream nextPut: $'
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> outputIsSelector: isSelector on: stream [
	stream nextPutAll: 'this.current_char.', isSelector
]

{ #category : #'compiling-scanner' }
SmaCCRustCodeGenerator >> outputLessThanMatch: each on: stream [
	stream nextPutAll: 'this.current_char <= '''.
	self writeCharacter: each first on: stream.
	stream nextPut: $'
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> outputMatchFor: aSmaCCCharacterEdge on: aStream without: aSelector [
	| pairs |
	pairs := self minMaxPairsFor: aSmaCCCharacterEdge without: aSelector.
	(aSelector notEmpty and: [ pairs notEmpty ]) ifTrue: [ aStream nextPutAll: ' || ' ].
	pairs size > 1 ifTrue: [ aStream nextPut: $( ].
	pairs
		do:
			[ :each | 
			each first = each last
				ifTrue:
					[ aStream nextPutAll: 'this.current_char == '''.
					self writeCharacter: each first on: aStream.
					aStream nextPut: $' ]
				ifFalse:
					[ aStream nextPutAll: '('''.
					self writeCharacter: each first on: aStream.
					aStream nextPutAll: '''..='''.
					self writeCharacter: each last on: aStream.
					aStream nextPutAll: ''').contains(&this.current_char)' ] ]
		separatedBy: [ aStream nextPutAll: ') || (' ].
	pairs size > 1 ifTrue: [ aStream nextPut: $) ]
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> outputMatchFor: aSmaCCCharacterEdge seen: aCollection on: stream [

	| isSelectors pairs invertedSelectors invertedPairs invertedChars invertMatch |
	isSelectors := self
		               closestIsExpressionsFor:
		               aSmaCCCharacterEdge transitionObjects
		               seen: aCollection.
	pairs := self
		         minMaxPairsFor: aSmaCCCharacterEdge transitionObjects
		         without: isSelectors
		         seen: aCollection.
	invertMatch := false.
	(SmaCCGrammar maximumCharacterValue > 255 and: [ 
		 isSelectors size + pairs size > 3 ]) ifTrue: [ 
		invertedChars := SmaCCGrammar allCharacters
			                 smaccRemoveAll:
				                 aSmaCCCharacterEdge transitionObjects;
			                 yourself.
		invertedSelectors := self
			                     closestIsExpressionsFor: invertedChars
			                     seen: aCollection.
		invertedPairs := self
			                 minMaxPairsFor: invertedChars
			                 without: invertedSelectors
			                 seen: aCollection.
		isSelectors size + pairs size
		> (invertedSelectors size + invertedPairs size) ifTrue: [ 
			isSelectors := invertedSelectors.
			pairs := invertedPairs.
			invertMatch := true ] ].
	invertMatch ifTrue: [ stream nextPutAll: '!(' ].
	isSelectors
		do: [ :each | self outputIsSelector: each on: stream ]
		separatedBy: [ stream nextPutAll: ' || ' ].
	pairs isEmpty ifFalse: [ 
		isSelectors notEmpty ifTrue: [ stream nextPutAll: ' || ' ].
		pairs
			do: [ :each1 | self outputMatchForTransition: each1 on: stream ]
			separatedBy: [ stream nextPutAll: ' || ' ] ].
	invertMatch ifTrue: [ stream nextPutAll: ')' ]
]

{ #category : #'compiling-scanner' }
SmaCCRustCodeGenerator >> outputRangeMatch: each on: stream [
	stream nextPutAll: '('''.
	self writeCharacter: each first on: stream.
	stream nextPutAll: '''..='''.
	self writeCharacter: each last on: stream.
	stream nextPutAll: ''').contains(&this.current_char)'
]

{ #category : #'compiling-scanner' }
SmaCCRustCodeGenerator >> outputSingleCharacterMatch: each on: stream [
	stream nextPutAll: 'this.current_char == '''.
	self writeCharacter: each first on: stream.
	stream nextPut: $'
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> returnSuper [ 
	^''
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> scannerClass: aString [
	| constructor source |
	scannerClass := model defineClass: aString asSubclassOf: SmaCCScanner.
	source := '{
	let mut scanner = crate::SmaCC::on(stream);
	scanner.scanForToken = scanForToken;
	scanner.emptySymbolTokenId = EMPTY_SYMBOL_TOKEN_ID;
	scanner.errorTokenId = ERROR_TOKEN_ID;
	scanner.tokenActions = TOKEN_ACTIONS.to_vec();
	scanner.keywordMap = &(*KEYWORD_MAP);'.
	self grammar ignoreCase ifTrue: [ source := source , '
	scanner.keywordFor = keywordFor;'].
	source := source , '
	scanner
}'.
	constructor := scannerClass
		compileConstructorArguments: (OrderedCollection with: (self variableClass name: 'stream' type: self readerType))
		source: source.
	constructor modifier public
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> selectorMap: aDictionary [
	| arrayMap |
	arrayMap := aDictionary isEmpty ifTrue: [ #() ] ifFalse: [ Array new: aDictionary keys asSortedCollection last ].
	aDictionary keysAndValuesDo: [ :key :value | arrayMap at: key put: value ].
	(self codeStream)
		cr;
		cr.
	self
		nextPutLine:
			'static TOKEN_ACTIONS: [Option<for<''a> fn(&mut Scanner<''a>) -> Result<SmaCCToken<''a>, SmaCCToken<''a>>>; '
				, arrayMap size printString , '] = ['.
	arrayMap
		do: [ :each | self outputClosureFor: each ]
		separatedBy:
			[ (self codeStream)
				nextPut: $,;
				cr ].
	self codeStream nextPutAll: '];'.
	self compileStaticIn: scannerClass
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> send: selectorString to: receiverString [
	| name |
	name := self methodNameFor: selectorString.
	^ name , '(' , receiverString , ')'
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> variableClass [
	^ SmaCCRustVariable
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> writeCharacter: aCharacter on: aStream [
	"Unicode must be four characters long in Java.
	Must use \r for unicode character D (carriage return), and \n for unicode A (newline)"

	| char |
	('''\' includes: aCharacter)
		ifTrue:
			[ aStream
				nextPut: $\;
				nextPut: aCharacter ]
		ifFalse:
			[ (aCharacter < $  or: [ aCharacter asInteger >= 128 ])
				ifTrue:
					[ char := aCharacter asInteger printStringBase: 16.
					[ char size >= 4 ] whileFalse: [ char := '0' , char ].
					char = '000D'
						ifFalse:
							[ char = '000A'
								ifFalse:
									[ aStream
										nextPutAll: '\u{';
										nextPutAll: char;
										nextPut: $} ]
								ifTrue: [ aStream nextPutAll: '\n' ] ]
						ifTrue: [ aStream nextPutAll: '\r' ] ]
				ifFalse: [ aStream nextPut: aCharacter ] ]
]

{ #category : #accessing }
SmaCCRustCodeGenerator >> writeMatchingCodeFor: aSmaCCNode [
	| matchedItem |
	(aSmaCCNode action notNil and: [ aSmaCCNode action size > 0 ])
		ifTrue:
			[ matchedItem := aSmaCCNode action asArray.
			(self codeStream)
				nextPutAll:
						(aSmaCCNode transitions isEmpty
								ifTrue: [ 'return ' , (self methodNameFor: 'RecordAndReportMatch') , '(' ]
								ifFalse: [ self methodNameFor: 'RecordMatch(' ]);
				nextPutAll: 'vec!['.
			matchedItem do: [ :each | self codeStream nextPutAll: each storeString ] separatedBy: [ self codeStream nextPut: $, ].
			self codeStream nextPutAll: '])'.
			(self codeStream)
				nextPut: $;;
				cr ].
	(aSmaCCNode transitions anySatisfy: [ :each | each isCharacterTransition ])
		ifTrue: [ self nextPutLine: (self methodNameFor: 'Step();') ]
]
