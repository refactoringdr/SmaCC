Class {
	#name : 'SmaCCStackNode',
	#superclass : 'Object',
	#instVars : [
		'state',
		'actionNode',
		'next'
	],
	#category : 'SmaCC_Runtime'
}

{ #category : 'instance creation' }
SmaCCStackNode class >> state: aState node: anObject next: aStackNode [
	^self new state: aState; node: anObject; next: aStackNode; yourself
]

{ #category : 'comparing' }
SmaCCStackNode >> <= anObject [
	^true
]

{ #category : 'copying' }
SmaCCStackNode >> copyStackObject: anObject [
	(anObject isKindOf: String) ifTrue: [ ^ anObject ].
	(anObject isKindOf: Collection) ifTrue: [ 
		^ anObject collect: [ :each | self copyStackObject: each ] ].
	(anObject isKindOf: SmaCCParseNode) ifTrue: [ ^ anObject copy ].
	^ anObject
]

{ #category : 'accessing' }
SmaCCStackNode >> next [

	^ next
]

{ #category : 'accessing' }
SmaCCStackNode >> next: aStackNode [

	next := aStackNode
]

{ #category : 'accessing' }
SmaCCStackNode >> node [

	^ actionNode
]

{ #category : 'accessing' }
SmaCCStackNode >> node: anObject [

	actionNode := anObject
]

{ #category : 'copying' }
SmaCCStackNode >> postCopy [
	actionNode := self copyStackObject:  actionNode.
	next := next copy
]

{ #category : 'printing' }
SmaCCStackNode >> printOn: aStream [
	aStream nextPutAll: 'SmaCCStackNode('.
	state printOn: aStream.
	aStream nextPutAll: '->'.
	actionNode printOn: aStream.
	aStream nextPutAll: ')'
]

{ #category : 'accessing' }
SmaCCStackNode >> state [

	^ state
]

{ #category : 'accessing' }
SmaCCStackNode >> state: anInteger [

	state := anInteger
]
