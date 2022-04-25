Class {
	#name : #AAAAAScanner,
	#superclass : #SmaCCScanner,
	#category : #'SmaCC_Runtime'
}

{ #category : #generated }
AAAAAScanner >> scanForToken [
	self step.
	currentCharacter == $a
		ifTrue:
			[ self recordMatch: #(2).
			self step.
			currentCharacter == $a ifTrue: [ (self scanForString: 'aaa') ifTrue: [ ^ self recordAndReportMatch: #(1) ] ] ].
	^ self reportLastMatch
]
