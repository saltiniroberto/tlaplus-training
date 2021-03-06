----------------------------- MODULE Peterson4 -----------------------------
EXTENDS TLAPS

VARIABLES flag, turn, pc

vars == <<flag, turn, pc>>

Not(i) == IF i = 0 THEN 1 ELSE 0

Init == /\ flag = [i \in {0,1} |-> FALSE]
        /\ turn = 0
        /\ pc = [self \in {0,1} |-> "a1"]
        
a1(self) == /\ pc[self] = "a1"
            /\ pc' = [pc EXCEPT ![self] = "a2"]
            /\ flag' = [flag EXCEPT ![self] = TRUE]
            /\ turn' = turn
            
a2(self) == /\ pc[self] = "a2"
            /\ pc' = [pc EXCEPT ![self] = "a3a"]
            /\ flag' = flag
            /\ turn' = Not(self)
            
a3a_cs(self) == 
    /\ pc[self] = "a3a"
    /\ ~flag[Not(self)]
    /\ pc' = [pc EXCEPT ![self] = "cs"]
    /\ UNCHANGED <<flag, turn>>
    
a3a_a3b(self) == 
    /\ pc[self] = "a3a"
    /\ flag[Not(self)]
    /\ pc' = [pc EXCEPT ![self] = "a3b"]
    /\ UNCHANGED <<flag, turn>>
    
a3b_cs(self) == 
    /\ pc[self] = "a3b"
    /\ turn = self
    /\ pc' = [pc EXCEPT ![self] = "cs"]
    /\ UNCHANGED <<flag, turn>>
   
a3b_a3a(self) == 
    /\ pc[self] = "a3b"
    /\ turn = Not(self)
    /\ pc' = [pc EXCEPT ![self] = "a3a"]
    /\ UNCHANGED <<flag, turn>>
                     
cs(self) == /\ pc[self] = "cs"
            /\ pc' = [pc EXCEPT ![self] = "a4"]
            /\ UNCHANGED <<flag, turn>>
            
a4(self) == /\ pc[self] = "a4"
            /\ pc' = [pc EXCEPT ![self] = "a1"]
            /\ flag' = [flag EXCEPT ![self] = FALSE]
            /\ turn' = turn            
            
proc(self) == 
    \/ a1(self) 
    \/ a2(self) 
    \/ cs(self) 
    \/ a4(self) 
    \/ a3a_cs(self) 
    \/ a3a_a3b(self) 
    \/ a3b_cs(self)
    \/ a3b_a3a(self)

Next == proc(0) \/ proc(1)

Spec == Init /\ [][Next]_vars

MutualExclusion == (pc[0] # "cs") \/ (pc[1] # "cs")

TypeOK == 
    /\ flag  \in [{0,1} -> BOOLEAN]
    /\ pc \in [{0, 1} -> {"a1", "a2", "a3a", "a3b", "cs", "a4"}]
    /\ turn \in {0,1}
    
I == \A i \in {0,1}:
    /\ (pc[i] \in {"a2", "a3a", "a3b", "cs", "a4"} => flag[i])
    /\ (pc[i] = "a1" => ~flag[i])
    /\ (pc[i] \in {"cs", "a4"}) => /\ ~(pc[Not(i)] \in {"cs","a4"})
                                 /\ (pc[Not(i)] \in {"a3a","a3b"} => turn = i) 

Inv == TypeOK /\ I

LEMMA Invariance == Spec => []Inv
<1>1 Init => Inv
    BY DEF Init, Inv, TypeOK, I
<1>2 Inv /\ [Next]_vars => Inv'
    <2>1 SUFFICES ASSUME Inv, Next
            PROVE Inv'
        BY DEF Inv, TypeOK, I, vars
    <2>2 TypeOK'
        BY <2>1 DEF Inv, Next, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, proc, TypeOK, Not
    <2>3 I'
        <3>1 SUFFICES ASSUME NEW j \in {0,1}
                PROVE I!(j)'
            BY DEF I
        <3>2 PICK i \in {0,1} : proc(i)
            BY <2>1 DEF Next
        <3>3 CASE i = j
            BY <2>1, <3>2, <3>3 DEF Inv, I, TypeOK, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not
        <3>4 CASE i # j
            BY <2>1, <3>2, <3>4 DEF Inv, I, TypeOK, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not
        <3>5 QED
            BY <3>3, <3>4
    <2>4 QED          
        BY <2>2, <2>3 DEF TypeOK, I, Not, Inv
<1>3 Inv => MutualExclusion
    BY DEF Inv, MutualExclusion, TypeOK, I, Not
<1>4 QED
    \* Temporal reasoning is required to prove 
    \* []Inv => []MutualExclusion from Inv => MutualExclusion
    \* Init /\ [][Next]_vars => []Inv from Init /\ [Next]_vars => Inv
    BY <1>1, <1>2, <1>3, PTL DEF Spec, MutualExclusion, Inv, TypeOK, I, Init, Next, vars, Not
    
\* For any valid, MutualExclusion is satisfied in all states. 
THEOREM Spec => []MutualExclusion
    <1>1 Inv => MutualExclusion
        BY DEF Inv, TypeOK, I, Not, MutualExclusion
    <1>2 QED
        BY <1>1, Invariance, PTL DEF MutualExclusion, Inv, TypeOK, I, Not

\* Liveness
    
Wait(i) == (pc[i] = "a3a") \/ (pc[i] = "a3b")
CS(i) == pc[i] = "cs"

P1 == Inv /\ pc[0] = "a3b" /\ turn = 0
    
LEMMA LP1 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) => P1 ~> CS(0)
    <1>1 <<Next /\ proc(0)>>_vars /\ P1 => CS(0)'
        BY DEF CS, P1, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not
    <1>2 [Next]_vars /\ P1 => P1' \/ CS(0)'
        <2>1 vars' = vars /\ P1 => P1'
            BY DEF vars, P1, Inv, TypeOK, I  
        <2>2 proc(1) /\ P1 => (I /\ pc[0] = "a3b" /\ turn = 0)'
            BY DEF Inv, TypeOK, I, P1, proc, I, Not, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4          
        <2>3 proc(1) /\ P1 => (TypeOK)'
            BY  DEF P1, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4
        <2>6 QED    
            BY <2>1, <2>2, <2>3, <1>1 DEF Next, P1, Inv
    <1>3 P1 => ENABLED <<proc(0)>>_vars
        PROOF OMITTED
    <1>4 QED
        BY <1>1, <1>2, <1>3, PTL DEF Next    

P2 == Inv /\ pc[0] = "a3a" /\ turn = 0
    
LEMMA LP2 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) => P2 ~> P1 \/ CS(0)
    <1>1 <<Next /\ proc(0)>>_vars /\ P2 => P1' \/ CS(0)'
        BY DEF P2, CS, P1, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not
    <1>2 [Next]_vars /\ P2 => P2' \/ P1' \/ CS(0)'
        <2>1 vars' = vars /\ P2 => P2'
            BY DEF vars, P2, Inv, TypeOK, I        
        <2>2 proc(1) /\ P2 => TypeOK'
            BY  DEF P2, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4
        <2>3 proc(1) /\ P2 => (I /\ pc[0] = "a3a" /\ turn = 0)'
            BY  DEF P2, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4
        <2>6 QED    
            BY <2>1, <2>2, <2>3, <1>1 DEF Next, P2, Inv
    <1>3 P2 => ENABLED <<proc(0)>>_vars
        PROOF OMITTED
    <1>4 QED    
        BY <1>1, <1>2, <1>3, PTL DEF Next

\**********

P == Inv /\ Wait(0) /\ turn = 0
LEMMA LP == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  P ~> CS(0)
    BY LP1, LP2, PTL DEF P, P1, P2, Wait

\**********
  
Q1 == Inv /\ Wait(0) /\ turn = 1 /\ flag[1] /\ pc[1] = "a2"

LEMMA LQ1 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q1 ~> P
    <1>1 <<Next /\ proc(1)>>_vars /\ Q1 => P'
        BY DEF CS, P, Q1, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 [Next]_vars /\ Q1 => Q1' \/ P'
        <2>1 vars' = vars /\ Q1 => Q1'
            BY DEF vars, Q1, Inv, TypeOK, I, Wait        
        <2>2 proc(0) /\ Q1 => Q1'
            BY  DEF Q1, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Wait
        <2>6 QED    
            BY <2>1, <2>2, <1>1 DEF Next
    <1>3 Q1 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>4 QED    
        BY <1>1, <1>2, <1>3, PTL DEF Next
     
Q2 == Inv /\ pc[0] = "a3a" /\ turn = 1 /\ ~flag[1]

LEMMA LQ2 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q2 ~> Q1 \/ CS(0) 
    <1>1 <<Next /\ proc(0)>>_vars /\ Q2 => CS(0)'
        BY DEF CS, Q2, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 <<Next /\ proc(1)>>_vars /\ Q2 => Q1'
        BY DEF CS, Q2, Q1, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>3 [Next]_vars /\ Q2 => Q2' \/ Q1' \/ CS(0)'
        <2>1 vars' = vars /\ Q2 => Q2'
            BY DEF vars, Q2, Inv, TypeOK, I, Wait        
        <2>6 QED    
            BY <2>1, <1>1, <1>2 DEF Next
    <1>4 Q2 => ENABLED <<proc(0)>>_vars
        PROOF OMITTED
    <1>5 Q2 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>6 QED       
        BY <1>1, <1>2, <1>3, <1>4, <1>5, PTL DEF Next
     
Q3 == Inv /\ pc[0] = "a3b" /\ turn = 1 /\ ~flag[1]

LEMMA LQ3 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q3 ~> Q1 \/ Q2
    <1>1 <<Next /\ proc(0)>>_vars /\ Q3 => Q2'
        BY DEF Q3, Q2, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 <<Next /\ proc(1)>>_vars /\ Q3 => Q1'
        BY DEF Q3, Q1, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>3 [Next]_vars /\ Q3 => Q3' \/ Q1' \/ Q2'
        <2>1 vars' = vars /\ Q3 => Q3'
            BY DEF vars, Q3, Inv, TypeOK, I, Wait        
        <2>6 QED    
            BY <2>1, <1>1, <1>2 DEF Next
    <1>4 Q3 => ENABLED <<proc(0)>>_vars
        PROOF OMITTED
    <1>5 Q3 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>6 QED
        BY <1>1, <1>2, <1>3, <1>4, <1>5, PTL DEF Next

\**********
     
QA == Inv /\ Wait(0) /\ turn = 1 /\ ~flag[1]
LEMMA LQA == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  QA ~> CS(0)
    BY LQ2, LQ3, LQ1, LP, PTL DEF QA, Wait, Q2, Q3 

\**********
     
Q4 == Inv /\ Wait(0) /\ turn = 1 /\ flag[1] /\ pc[1] = "a3b" 
Q5 == Inv /\ Wait(0) /\ turn = 1 /\ flag[1] /\ pc[1] = "cs" 

LEMMA LQ4 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q4 ~> Q5
    <1>1 <<Next /\ proc(1)>>_vars /\ Q4 => Q5'
        BY DEF Q4, Q5, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 [Next]_vars /\ Q4 => Q4' \/ Q5'
        <2>1 vars' = vars /\ Q4 => Q4'
            BY DEF vars, Q4, Inv, TypeOK, I, Wait        
        <2>2 proc(0) /\ Q4 => Q4'
            BY  DEF Q4, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Wait
        <2>6 QED    
            BY <2>1, <2>2, <1>1 DEF Next
    <1>3 Q4 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>6 QED
        BY <1>1, <1>2, <1>3, PTL DEF Next
      
Q6 == Inv /\ Wait(0) /\ turn = 1 /\ flag[1] /\ pc[1] = "a3a"

LEMMA LQ6 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q6 ~> Q4 
    <1>1 <<Next /\ proc(1)>>_vars /\ Q6 => Q4'
        BY DEF Q6, Q4, Q5, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 [Next]_vars /\ Q6 => Q6' \/ Q4' 
        <2>1 vars' = vars /\ Q6 => Q6'
            BY DEF vars, Q6, Inv, TypeOK, I, Wait        
        <2>2 proc(0) /\ Q6 => Q6'
            BY  DEF Q6, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Wait
        <2>6 QED    
            BY <2>1, <2>2, <1>1 DEF Next
    <1>3 Q6 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>4 QED 
        BY <1>1, <1>2, <1>3, PTL DEF Next
 
Q7 == Inv /\ Wait(0) /\ turn = 1 /\ flag[1] /\ pc[1] = "a4"

LEMMA LQ5 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q5 ~> Q7
    <1>1 <<Next /\ proc(1)>>_vars /\ Q5 => Q7'
        BY DEF Q5, Q7, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 [Next]_vars /\ Q5 => Q5' \/ Q7'
        <2>1 vars' = vars /\ Q5 => Q5'
            BY DEF vars, Q5, Inv, TypeOK, I, Wait        
        <2>2 proc(0) /\ Q5 => Q5'
            BY  DEF Q5, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Wait
        <2>6 QED    
            BY <2>1, <2>2, <1>1 DEF Next
    <1>3 Q5 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>4 QED
        BY <1>1, <1>2, <1>3, PTL DEF Next

LEMMA LQ7 == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q7 ~> QA
    <1>1 <<Next /\ proc(1)>>_vars /\ Q7 => QA'
        BY DEF QA, Q7, Inv, TypeOK, I, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Not, Wait
    <1>2 [Next]_vars /\ Q7 => QA' \/ Q7'
        <2>1 vars' = vars /\ Q7 => Q7'
            BY DEF vars, Q7, Inv, TypeOK, I, Wait        
        <2>2 proc(0) /\ Q7 => Q7'
            BY  DEF Q7, Inv, TypeOK, I, Not, proc, a1, a2, a3a_cs, a3a_a3b, a3b_cs, a3b_a3a, cs, a4, Wait
        <2>6 QED    
            BY <2>1, <2>2, <1>1 DEF Next
    <1>3 Q7 => ENABLED <<proc(1)>>_vars
        PROOF OMITTED
    <1>4 QED
        BY <1>1, <1>2, <1>3, PTL DEF Next

\**********
     
QB == Inv /\ Wait(0) /\ turn = 1 /\ flag[1]
LEMMA LQB == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  QB ~> CS(0)
    <1>1 Inv /\ flag[1] => pc[1] = "a2" \/ pc[1] = "a3a" \/ pc[1] = "a3b" \/ pc[1] = "cs" \/ pc[1] = "a4"
        BY DEF Inv, TypeOK, I
    <1>2 QED    
    BY <1>1, LQ1, LP, LQ4, LQ6, LQ5, LQ7, LQA, PTL DEF QB, Q1, Q4, Q6, Q5, Q7, QA 

\**********
     
Q == Inv /\ Wait(0) /\ turn = 1
LEMMA LQ == [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) =>  Q ~> CS(0)
    BY LQA, LQB, PTL DEF QA, QB, Inv, TypeOK, Q
     
\**********
     
THEOREM Liveness == Spec /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) => Wait(0) ~> CS(0)
<1>1 []Inv /\ [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) => Wait(0) ~> CS(0)
    <2>1 SUFFICES [][Next]_vars /\ WF_vars(proc(0)) /\ WF_vars(proc(1)) => (Inv /\ Wait(0)) ~> CS(0)
        BY PTL
    <2>2 Inv => turn = 0 \/ turn = 1
        BY DEF Inv, TypeOK    
    <2>5 QED
        BY <2>2, LP, LQ, PTL DEF P, Q 
<1>2 QED   
    BY Invariance, <1>1 DEF Init, Spec, Wait, CS, Next, proc, Inv, TypeOK, I, Not    
=============================================================================
\* Modification History
\* Last modified Tue Oct 13 13:08:05 AEST 2020 by raghavendra
\* Created Mon Oct 05 23:14:50 AEST 2020 by raghavendra
