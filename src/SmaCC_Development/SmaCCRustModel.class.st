Class {
	#name : #SmaCCRustModel,
	#superclass : #Object,
	#instVars : [
		'classes'
	],
	#category : #'SmaCC_Development-Compiler'
}

{ #category : #adding }
SmaCCRustModel >> addClass: aSmaCCCSharpClass [
	^ classes at: aSmaCCCSharpClass name asSymbol put: aSmaCCCSharpClass
]

{ #category : #accessing }
SmaCCRustModel >> classFor: aBehavior [
	#(#(#Object nil 'object') #(#SmaCCToken #Object 'Token') #(#Collection #Object 'IList') #(#OrderedCollection #Object 'IList') #(#SmaCCParseNodeVisitor #Object 'ParseNodeVisitor') #(#SmaCCParseNode #Object 'ParseNode') #(#UndefinedObject #Object 'UndefinedObject'))
		do:
			[ :each | 
			each first = aBehavior name
				ifTrue:
					[ | newClass |
					newClass := self typeClass newName: each last.
					newClass
						model: self;
						superclassName: (each at: 2);
						doNotGenerate: true.
					self addClass: newClass.
					^ newClass ] ].
	self error: 'This is not supported'
]

{ #category : #accessing }
SmaCCRustModel >> classNamed: aSymbol [
	^ classes
		at: aSymbol
		ifAbsent: [ (Smalltalk at: aSymbol asSymbol ifAbsent: [ nil ]) ifNotNil: [ :value | self classFor: value ] ]
]

{ #category : #visiting }
SmaCCRustModel >> classesDo: aBlock [
	classes do: aBlock
]

{ #category : #compiling }
SmaCCRustModel >> defineClass: aString asSubclassOf: aSmaCCClass [
	| newClass |
	newClass := self typeClass newName: aString.
	newClass superclassName: aSmaCCClass name.
	newClass model: self.
	self addClass: newClass.
	^ newClass
]

{ #category : #initialization }
SmaCCRustModel >> initialize [
	classes := Dictionary new
]

{ #category : #compiling }
SmaCCRustModel >> typeClass [
	^SmaCCRustClass
]
