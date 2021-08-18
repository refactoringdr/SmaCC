Class {
	#name : #SmaCCStackTest,
	#superclass : #TestCase,
	#category : #'SmaCC_Tests'
}

{ #category : #tests }
SmaCCStackTest >> testDismissStackTop [
	| stack result |
	stack := SmaCCStack new.
	stack shift: #foo to: 1.
	stack shift: #bar to: 2.
	stack shift: #baz to: 3.
	result := stack dismissStackTopForErrorRecovery: 2.
	self assert: result equals: #(#bar #baz).
	self assert: stack size equals: 1.

]

{ #category : #tests }
SmaCCStackTest >> testEquality [

	| stack1 stack2 |
	stack1 := SmaCCStack new.
	stack2 := SmaCCStack new.
	self assert: stack1 equals: stack2.
	stack1 shift: #foo to: 1.
	stack2 shift: #foo to: 1.
	self assert: stack1 equals: stack2.
	stack1 shift: #bar to: 2.
	stack2 shift: #bar to: 2.
	self assert: stack1 equals: stack2.
	stack1 shift: #baz to: 3.
	stack2 shift: #bax to: 3.
	self deny: stack1 equals: stack2.
	stack1 reduce: 1 do: [  ].
	stack2 reduce: 1 do: [   ].
	self assert: stack1 equals: stack2.
	stack1 shift: #baz to: 3.
	stack2 shift: #baz to: 4.
	self deny: stack1 equals: stack2.
	

]

{ #category : #tests }
SmaCCStackTest >> testShiftAndReduce [

	| stack |
	stack := SmaCCStack new.
	stack shift: #foo to: 1.
	self assert: stack topNode equals: #foo.
	self assert: stack topState equals: 1.
	self assert: stack size equals: 1.
	stack shift: #bar to: 2.
	self assert: stack topNode equals: #bar.
	self assert: stack topState equals: 2.
	self assert: stack size equals: 2.
	stack
		reduce: 1
		do: [ :items | self assert: items first equals: #bar ].
	stack shift: #baz to: 3.
	stack reduce: 2 do: [ :items | 
		self assert: (items at: 1) equals: #foo.
		self assert: (items at: 2) equals: #baz ]
]

{ #category : #tests }
SmaCCStackTest >> testStartingState [
	| stack |
	stack := SmaCCStack new.
	self assert: stack isAtStartingState.
	stack shift: #foo to: 1.
	self assert: stack isAtStartingState not.
	
]
