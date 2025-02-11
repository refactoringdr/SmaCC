Class {
	#name : #SmaCCSendRuleDebugAction,
	#superclass : #SmaCCTransformationToolkitDebugAction,
	#category : #'SmaCC_Rewrite_Engine_UI'
}

{ #category : #registration }
SmaCCSendRuleDebugAction class >> gtActionFor: aDebugger [
	<gtSmaCCTransformationStack>
	
	^ (self forDebugger: aDebugger) icon: (self iconNamed: #glamorousInto)
]

{ #category : #accessing }
SmaCCSendRuleDebugAction >> defaultKeymap [
	^ $O meta
]

{ #category : #accessing }
SmaCCSendRuleDebugAction >> defaultLabel [
	^ 'Into'
]

{ #category : #accessing }
SmaCCSendRuleDebugAction >> defaultOrder [
	^ 90
]

{ #category : #actions }
SmaCCSendRuleDebugAction >> executeAction [
	| first |
	first := true.
	self
		stepUntil: [ :context | 
			first
				ifTrue: [ first := false ]
				ifFalse: [ self session isRewriteContext: context ] ]
]

{ #category : #accessing }
SmaCCSendRuleDebugAction >> help [
	^ 'Step into message'
]
