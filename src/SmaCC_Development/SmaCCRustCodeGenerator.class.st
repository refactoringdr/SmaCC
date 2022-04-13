Class {
	#name : #SmaCCRustCodeGenerator,
	#superclass : #SmaCCTypedLanguageCodeGenerator,
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> codeTemplatesArray [
	^ super codeTemplatesArray
		,
			#(
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
			#(#override 'override ')
			#(#parentName 'Parent')
			#(#readerType 'System.IO.TextReader')
			#(#reduceActionArrayType 'ReduceAction[]') 
			#(#reduceActionLiteralStart 'new ReduceAction[] {') 
			#(#stringType '&str') 
			#(#unsignedShort 'usize') 
			#(#unsignedShortArray 'usize[]') 
			#(#unsignedShortArrayArray 'usize[][]') 
			#(#uppercaseString: '<1s>.ToUpper()'))
]

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> parseSourceSelector [
	^ #canParseSmalltalk:
]

{ #category : #'code generation templates' }
SmaCCRustCodeGenerator class >> typeName [
	^ #Rust
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> compileKeywordInitializerUsing: keywordMapDictionary [
	| method stream dataStream |
	keywordMapDictionary isEmpty ifTrue: [ ^ self ].
	stream := self outputStreamClass on: String new.
	stream
		nextPutAll: 'let mut map: HashMap<usize, HashMap<&str, usize>> = HashMap::new();';
		cr;
		nextPutAll: 'let arr = [';
		cr.
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
	dataStream contents
		do:
			[ :each | 
			stream nextPutAll: '('.
			each first storeOn: stream.
			stream
				nextPutAll: ',"';
				nextPutAll: each second;
				nextPutAll: '",'.
			each third storeOn: stream.
			stream nextPutAll: '),' ]
		separatedBy: [ stream cr ].
	stream
		nextPutAll: '];';
		cr.
	stream
		nextPutAll:
			' for (state, word, id) in arr {
			        let dict = map.entry(state).or_insert(HashMap::new());
			        dict.insert(word, id);
			    }
			    map
			}'.
	method := scannerClass
		compile: (self methodNameFor: 'initializeKeywordMap')
		type: 'HashMap<usize, HashMap<&''static str, usize>>'
		arguments: #()
		source: stream contents
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> compileMethodIn: modelClass [
	modelClass compileMethod: self codeStream contents
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

{ #category : #compiling }
SmaCCRustCodeGenerator >> methodNameFor: selectorString [
	| name |
	#(#('=' 'Equals') #('hash' 'GetHashCode') #('match:inContext:' 'MatchInContext') #('matchCollection:to:inContext:' 'MatchCollectionInContext') #('AcceptNode' 'AcceptNode') #('AcceptVisitor' 'AcceptVisitor') #('BasicCreateToken' 'BasicCreateToken') #('checkForKeyword' 'CheckForKeyword') #('Comment' 'comment') #('CreateScanner' 'CreateScanner') #('CreateToken(value)' 'CreateToken(value)') #('processReduceAction' 'ProcessReduceAction') #('RecordAndReportMatch' 'RecordAndReportMatch') #('RecordMatch(' 'RecordMatch(') #('ReduceFor' 'ReduceFor') #('Step();' 'Step();') #('Whitespace' 'whitespace'))
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

{ #category : #compiling }
SmaCCRustCodeGenerator >> returnSuper [ 
	^''
]

{ #category : #visiting }
SmaCCRustCodeGenerator >> selectorMap: aDictionary [
	| arrayMap |
	aDictionary isEmpty ifTrue: [ ^ self ].
	arrayMap := Array new: aDictionary keys asSortedCollection last.
	aDictionary keysAndValuesDo: [ :key :value | arrayMap at: key put: value ].
	(self codeStream)
		cr;
		cr.
	self
		nextPutLine:
			'static TOKEN_ACTIONS: [Option<for<''a> fn(&mut Scanner<''a>) -> Result<SmaCCToken<''a>, ScannerError>; '
				, arrayMap size printString , '] = ['.
	arrayMap
		do: [ :each | self outputClosureFor: each ]
		separatedBy:
			[ (self codeStream)
				nextPut: $,;
				cr ].
	self codeStream nextPutAll: '];'.
	self compileMethodIn: scannerClass	"self
		startPublicOverrideMethod;
		nextPutLine: (self method: 'tokenActions' type: self collectionType);
		nextPutStatement: (self return: arrayMap storeString);
		endMethod;
		compileMethodIn: self scannerClass"
]

{ #category : #compiling }
SmaCCRustCodeGenerator >> variableClass [
	^ SmaCCRustVariable
]
