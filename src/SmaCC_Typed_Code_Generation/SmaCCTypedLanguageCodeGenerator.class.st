Class {
	#name : #SmaCCTypedLanguageCodeGenerator,
	#superclass : #SmaCCCodeGenerator,
	#instVars : [
		'matchActions',
		'reduceActions'
	],
	#category : #'SmaCC_Typed_Code_Generation'
}

{ #category : #'code generation templates' }
SmaCCTypedLanguageCodeGenerator class >> codeTemplatesArray [
	^ super codeTemplatesArray
		,
			#(
			#(#assignmentTo:from: '<1s> = <2s>') 
			#(#bitXor:with: '<1s> ^ <2s>')
			#(#cast:to: '((<2s>)(<1s>))')
			#(#collectionVariableItemsIn:forCollectionGetter:andVariableGetter: 'SmaCCParseNode.collectionVariable(<1s>, "<2s>", "<3s>")')
			#(#endConditionalString '}')
			#(#endDoWhileLoopWithClause: '} while (<1s>)')
			#(#endLiteralArray '}')
			#(#endMethodString '}')
			#(#ifFalseReturn: 'if (!!(<1s>)) return false') #(#integerType 'int')
			#(#literalArraySeparator ', ')
			#(#newObject: 'new <1s>()')
			#(#notNilCheckFor: 'if (<1s> !!= null) {')
			#(#private 'private ')
			#(#protected 'protected ')
			#(#public 'public ')
			#(#receiverName 'this')
			#(#return: 'return <1s>')
			#(#startDoWhileLoop 'do {')
			#(#startIfWithClause: 'if (<1s>) {')
			#(#statementSeparator ';')
			#(#static 'static ')
			#(#undefinedObject 'null')
			#(#variableDeclaration:ofType: '<2s> <1s>;')
			#(#variableItemIn:forVariableGetter: 'SmaCCParseNode.variable(<1s>, "<2s>")')
			#(#virtual 'virtual ')
			#(#voidType 'void'))
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> acceptStateEdge: aSmaCCStateEdge [
	| stream |
	stream := self outputStreamClass on: String new.
	aSmaCCStateEdge transitionObjects
		do:
			[ :each | 
			stream
				nextPutAll: 'state == "';
				nextPutAll: each;
				nextPut: $" ]
		separatedBy: [ stream nextPutAll: ' || ' ].
	^ stream contents
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> accessOperator [
	^ '.'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> addVariable: aSmaCCVariableDefinition forDefinition: aSmaCCNodeClassDefinition [
	| type instVarName variable |
	instVarName := self nonKeywordNameFor: aSmaCCVariableDefinition sourceVariableName.
	type := aSmaCCVariableDefinition type.
	variable := aSmaCCNodeClassDefinition modelClass addVariable: instVarName type: type name.
	aSmaCCVariableDefinition isCollection ifTrue: [ variable initializer: (self newCollectionOfSize: 2) ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> assignArray: arrayString index: anInteger to: valueString [
	^ super
		assignArray: arrayString
		index: anInteger - 1
		to: valueString
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> at: aString index: anInteger [
	^ super at: aString index: anInteger - 1
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> basicCompileSourceFor: aSmaCCReduceAction [
	| source |
	source := aSmaCCReduceAction rhs reduceAction source.
	^ reduceActions
		indexOf: source
		ifAbsent:
			[ reduceActions add: source.
			reduceActions size ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> comment: aString [
	^ '/*' , (aString copyReplaceAll: '*/' with: '* /') , '*/'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileAcceptNodeMethodFor: aSmaCCVisitorClassDefinition rootNode: aSmaCCClassDefinition [
	self
		startPublicOverrideMethod;
		nextPutLine:
				(self
						method: (self methodNameFor: 'AcceptNode')
						type: self objectType
						argumentName: 'aSmaCCParseNode'
						argumentType: 'ParseNode' , self dereferenceOp);
		nextPutStatement:
				'return (' , (self cast: 'aSmaCCParseNode' to: aSmaCCClassDefinition fullName , self dereferenceOp) , ').'
						, (self methodNameFor: 'AcceptVisitor') , '(this)';
		endMethod;
		compileMethodIn: aSmaCCVisitorClassDefinition modelClass
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileChanges [
	model classesDo: [ :each | each save ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileInitializeMethod: aSmaCCNodeClassDefinition [
	"The collections are initialized by the variable definitions"
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileMethodWithoutFormattingIn: modelClass [
	modelClass compileMethod: self codeStream contents
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileReductionActions [
	self
		startPublicOverrideMethod;
		nextPutLine:
				(self
						method: (self methodNameFor: 'processReduceAction')
						type: self objectType
						argumentName: 'nodes'
						argumentType: self collectionType
						argumentName: 'actionId'
						argumentType: self unsignedShort);
		nextPutLine: 'switch (actionId) {'.
	reduceActions keysAndValuesDo: [ :index :each | self outputSwitchStatementwithIndex: index each: each ].
	self
		nextPutLine: '}';
		nextPutLine: 'return null;';
		endMethod;
		compileMethodIn: parserClass
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> compileScannerClassIntoParser [
	| method |
	method := parserClass
		compile: (self methodNameFor: 'CreateScanner')
		type: 'SmaCCScanner' , self dereferenceOp
		arguments: (OrderedCollection with: (SmaCCCSharpVariable name: 'reader' type: self readerType))
		source: 'return new ' , scannerClass simpleName , '(reader);'.
	method modifier public override
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> convertToString: aString [
	^ aString
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> createNodeReduceAction: aSmaCCRHS pullUpFrom: anInteger [
	self resetCodeStream.
	self nextPutLine: '{'.
	self nextPutLine: (self variableDeclaration: 'result' ofType: aSmaCCRHS nodeType fullName).
	self
		nextPutStatement:
			(self
				assignmentTo: 'result'
				from:
					(anInteger isZero
						ifTrue: [ self newObject: aSmaCCRHS nodeType fullName ]
						ifFalse: [ self cast: (self at: 'nodes' index: anInteger) to: aSmaCCRHS nodeType fullName ])).
	SmaCCReduceActionGenerator
		generate: aSmaCCRHS
		pullUp: anInteger
		on: self.
	self nextPutStatement: (self return: 'result').
	self nextPutLine: ''.
	self nextPutLine: '}'.
	^ self codeStream contents
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> defaultNodeReductionSource: aReduction [
	aReduction index = 0 ifTrue: [ ^ 'return ' , self undefinedObject , ';' ].
	^ self return: (self at: 'nodes' index: aReduction index) , self statementSeparator
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> defaultReductionSource [
	^ 'return this' , self accessOperator , (self methodNameFor: 'ReduceFor') , '(nodes);'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> defineClass: aString asSubclassOf: aSmaCCClass [
	model defineClass: aString asSubclassOf: aSmaCCClass.
	^ model classNamed: aString asSymbol
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> dereferenceOp [
	^ ''
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> initialize [
	super initialize.
	model := self modelClass new.
	matchActions := OrderedCollection new.
	reduceActions := OrderedCollection new
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> method: aString type: typeString [
	^ typeString , ' ' , (self methodNameFor: aString) , '() {'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> method: aString type: typeString argumentName: argumentNameString argumentType: argumentTypeString [
	^ typeString , ' ' , (self methodNameFor: aString) , '(' , argumentTypeString , ' ' , argumentNameString , ') {'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> method: aString type: typeString argumentName: firstArgumentNameString argumentType: firstArgumentTypeString argumentName: secondArgumentNameString argumentType: secondArgumentTypeString [
	^ typeString , ' ' , (self methodNameFor: aString) , '(' , firstArgumentTypeString , ' ' , firstArgumentNameString , ', '
		, secondArgumentTypeString , ' ' , secondArgumentNameString , ') {'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> modelClass [
	self subclassResponsibility
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> outputInvertedMatchFor: aSmaCCCharacterEdge on: stream [
	| char |
	char := Character
		value:
			((0 to: SmaCCGrammar maximumCharacterValue)
				detect: [ :each | (aSmaCCCharacterEdge transitionObjects includes: (Character value: each)) not ]).
	stream
		nextPutAll: 'currentCharacter != ''';
		nextPut: char;
		nextPut: $'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> outputMatchFor: aSmaCCCharacterEdge on: aStream without: aSelector [
	| pairs |
	pairs := self minMaxPairsFor: aSmaCCCharacterEdge without: #().
	pairs size == 1 ifFalse: [ aStream nextPut: $( ].
	pairs
		do:
			[ :each | 
			each first = each last
				ifTrue: [ aStream nextPutAll: 'currentCharacter == ''' ]
				ifFalse:
					[ aStream nextPutAll: 'currentCharacter >= '''.
					self writeCharacter: each first on: aStream.
					aStream nextPutAll: ''' && currentCharacter <= ''' ].
			self writeCharacter: each last on: aStream.
			aStream nextPut: $' ]
		separatedBy: [ aStream nextPutAll: ') || (' ].
	pairs size == 1 ifFalse: [ aStream nextPut: $) ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> outputStreamClass [
	^ CurlyBracketWriteStream
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> outputSwitchStatementwithIndex: index each: each [
	self
		nextPutLine: 'case ' , index printString , ': {';
		nextPut: Character tab;
		nextPutLine: each;
		nextPutLine: '}'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> parserClass: aString [
	| method |
	super parserClass: aString.
	method := parserClass
		compileConstructorArguments: (OrderedCollection with: (self variableClass name: 'text' type: self stringType))
		source: ''.
	method initializer: self returnSuper , '(text)'.
	method modifier public.
	method := parserClass
		compileConstructorArguments: (OrderedCollection with: (self variableClass name: 'reader' type: self readerType))
		source: ''.
	method initializer: self returnSuper , '(reader)'.
	method modifier public.
	method := parserClass
		compileConstructorArguments: (OrderedCollection with: (self variableClass name: 'scanner' type: 'SmaCCScanner'))
		source: ''.
	method initializer: self returnSuper , '(scanner)'.
	method modifier public
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> reduceAction: anArray [
	^ 'new ReduceAction(' , anArray first printString , ', ' , (anArray at: 2) printString , ', ' , anArray last printString
		, ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> removeOldMethods [
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> removeOldMethodsFrom: aSmaCCCSharpClass [
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> returnSuper [
	self subclassResponsibility
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> scannerActionFor: aString [
	aString = '<comment>' ifTrue: [^self methodNameFor: 'Comment'].
	aString = '<whitespace>' ifTrue: [^self methodNameFor: 'Whitespace'].
	^nil
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> scannerClass: aString [
	| constructor |
	scannerClass := model defineClass: aString asSubclassOf: SmaCCScanner.
	constructor := scannerClass
		compileConstructorArguments: (OrderedCollection with: (self variableClass name: 'reader' type: self readerType))
		source: ''.
	constructor initializer: self returnSuper , '(reader)'.
	constructor modifier public
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> send: selectorString to: receiverString [
	| name |
	name := self methodNameFor: selectorString.
	^ receiverString , '.' , name , '()'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> send: selectorString to: receiverString with: argumentString [
	| name |
	selectorString = #parent: ifTrue: [ ^ receiverString , '.' , self parentName , ' = ' , argumentString ].
	name := self methodNameFor: selectorString.
	^ receiverString , '.' , name , '(' , argumentString , ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> send: selectorString to: receiverString with: firstArgumentString with: secondArgumentString [
	| name |
	name := self methodNameFor: selectorString.
	^ receiverString , '.' , name , '(' , firstArgumentString , ', ' , secondArgumentString , ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> send: selectorString to: receiverString with: firstArgumentString with: secondArgumentString with: thirdArgumentString [
	| name |
	name := self methodNameFor: selectorString.
	^ receiverString , '.' , name , '(' , firstArgumentString , ', ' , secondArgumentString , ', ' , thirdArgumentString , ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> superMessage: aString [
	^ self returnSuper , self accessOperator , (self methodNameFor: aString) , '()'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> superMessage: aString argument: argumentString [
	^ self returnSuper , self accessOperator , (self methodNameFor: aString) , '(' , argumentString , ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> superMessage: aString argument: firstArgumentString argument: secondArgumentString [
	^ self returnSuper , self accessOperator , (self methodNameFor: aString) , '(' , firstArgumentString , ', '
		, secondArgumentString , ')'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> variableClass [
	self subclassResponsibility
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> variableNameForMatch: matchedItem [
	| variableName variable isNew initializerStream |
	isNew := false.
	variableName := 'matchActions'
		,
			(matchActions
				indexOf: matchedItem
				ifAbsent:
					[ isNew := true.
					matchActions
						add: matchedItem;
						size ]) printString.
	isNew
		ifTrue:
			[ variable := scannerClass addVariable: variableName type: self unsignedShortArray.
			variable modifier static private.
			initializerStream := WriteStream on: String new.
			initializerStream
				nextPutAll: 'new ';
				nextPutAll: self unsignedShortArray;
				nextPutAll: ' {'.
			matchedItem do: [ :each | initializerStream print: each ] separatedBy: [ initializerStream nextPutAll: ', ' ].
			initializerStream nextPut: $}.
			variable initializer: initializerStream contents ].
	^ variableName
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> variableReference: aSmaCCVariableDefinition in: aString [
	^ aString , self accessOperator , aSmaCCVariableDefinition getterMethodName , '()'
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> writeCharacter: aCharacter on: aStream [
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
					[ char size = 4 ] whileFalse: [ char := '0' , char ].
					char = '000D'
						ifFalse:
							[ char = '000A'
								ifFalse:
									[ aStream
										nextPutAll: '\u';
										nextPutAll: char ]
								ifTrue: [ aStream nextPutAll: '\n' ] ]
						ifTrue: [ aStream nextPutAll: '\r' ] ]
				ifFalse: [ aStream nextPut: aCharacter ] ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> writeMatchingCodeFor: aSmaCCNode [
	| matchedItem |
	(aSmaCCNode action notNil and: [ aSmaCCNode action size > 0 ])
		ifTrue:
			[ matchedItem := aSmaCCNode action asArray.
			(self codeStream)
				nextPutAll:
						(aSmaCCNode transitions isEmpty
								ifTrue: [ 'return ' , (self methodNameFor: 'RecordAndReportMatch') , '(' ]
								ifFalse: [ self methodNameFor: 'RecordMatch(' ]);
				nextPutAll: (self variableNameForMatch: matchedItem);
				nextPutAll: ');';
				cr ].
	(aSmaCCNode transitions anySatisfy: [ :each | each isCharacterTransition ])
		ifTrue: [ self nextPutLine: (self methodNameFor: 'Step();') ]
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> writeTransitionTableEntry: anArray on: aStream firstIsType: aBoolean [
	aStream
		cr;
		tab;
		nextPutAll: self newUnsignedShortArray.
	anArray do: [ :each | aStream print: each ] separatedBy: [ aStream nextPutAll: self literalArraySeparator ].
	aStream nextPut: $}
]

{ #category : #visiting }
SmaCCTypedLanguageCodeGenerator >> writeTransitionTableMethod: stream withMethods: total withSize: size [
	| methods |
	methods := OrderedCollection new.
	1 to: total do: [ :index | methods add: 'transitionTable' , index printString , '(table);' ].
	self
		startStaticPrivateMethod;
		nextPutLine: (self method: '_transitionTable' type: self unsignedShortArrayArray);
		nextPutLine: 'int [][] table = new int[' , size printString , '][];'.
	methods do: [ :each | self nextPutLine: each ].
	self
		nextPutStatement: (self return: 'table');
		endMethod;
		compileMethodWithoutFormattingIn: parserClass
]
