# https://github.com/Sveino/Inst4CIM-KG/tree/develop/rdfs-improved#whitespace-in-definitions
# https://github.com/Sveino/Inst4CIM-KG/issues/6

delete {?x ?p ?old}
insert {?x ?p ?new}
where {
  ?x ?p ?old
  filter(isLiteral(?old))
  bind(str(?old) as ?oldStr)
  filter(regex(?oldStr,"^\\s|\\s$"))
  bind(replace(replace(?oldStr,"^\\s+",""),"\\s+$","") as ?newStr)
  bind(if(lang(?old)!="",strlang(?newStr,lang(?old)),?newStr) as ?new)
};

