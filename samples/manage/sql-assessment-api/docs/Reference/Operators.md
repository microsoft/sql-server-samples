# Operators <!-- omit in toc -->

With the SQL Assessment API, you can use different kinds of operators to make your assessment even more precise.

## In This Section <!-- omit in toc -->

- [Logical](#logical)
- [String](#string)
- [Math](#math)
- [Set](#set)
- [Comparison](#comparison)

## Logical

|Operator|Arguments|Description|
|-|:-:|-|
|not|(*x*)|Logical not.|
|and|(*a*..\*)|Logical AND. Returns `false` without arguments.|
|or|(*a*..\*)|Logical OR. Returns `true` without arguments.|

## String

|Operator|Arguments|Description|
|-|:-:|-|
|indexof|(*str_a*, *str_b*)|Finds a zero-based index of the first *str_b* occurrence in the string *str_a*. Case-sensitive.|
|iindexof|(*str_a*, *str_b*)|Finds a zero-based index of the first *str_b* occurrence in the string *str_a*. Case-insensitive.|
|startswith|(*str_a*, *str_b*)|Returns `true` if the string *str_a* starts with the string *str_b*. Case-sensitive.|
|istartswith|(*str_a*, *str_b*)|Returns `true` if the string *str_a* starts with the string *str_b*. Case-insensitive.|
|endswith|(*str_a*, *str_b*)|Returns `true` if the string *str_a* ends with the string *str_b*. Case-sensitive.|
|iendswith|(*str_a*, *str_b*)|Returns `true` if the string *str_a* ends with the string *str_b*. Case-insensitive.|

## Math

|Operator|Arguments|Description|
| - |:-:| - |
|ceiling|*x*|Rounds *x* to the nearest greater or equal value.|
|floor|*x*|Rounds *x* to the nearest lower or equal value.|
|max|(*a*, *b*)|Returns maximum of *a* and *b*.|
|min|(*a*, *b*)|Returns minimum of *a* and *b*.|
|mul|(*a*..\*)|Arithmetic multiplication.|
|div|(*a*, *b*)|Arithmetic division of *a* by *b*.|
|mod|(*a*, *b*)|Arithmetic remainder of *a* divided by *b*.|
|add|(*a*..\*)|Arithmetic sum.|
|sub|(*a*, *b*)|Arithmetic difference of *a* and *b*.|
|bitand|(*a*..\*)|Bitwise AND.|
|bitor|(*a*..\*)|Bitwise OR.|
|bitxor|(*a*..\*)|Bitwise XOR.|

## Set

|Operator|Arguments|Description|
| - | :-: |-|
|intersect|(*a*, *b*)|Sets intersection of *a* and *b* arguments. Case-sensitive.|
|in|(*a*, *b*)|Checks if the argument *a* was found in *b*. The *b* argument represents a collection. Case-sensitive.|
|iin|(*a*, *b*)|Checks if the argument *a* was found in *b*. The *b* argument represents a collection. Case-insensitive.|

## Comparison

|Operator|Synonyms|Arguments| Description|
| - | - | :-: | - |
|lt|less|(*a*, *b*)|Checks if the argument *a* is less than the argument *b*.|
|gt|greater|(*a*, *b*)|Checks if the argument *a* is greater than the argument *b*.|
|eq|equal|(*a*, *b*)|Checks if both arguments are equal. Case-sensitive.|
|ieq||(*a*, *b*)|Checks if both arguments are equal. Case-insensitive.|
|ge|greaterequal|(*a*, *b*)|Checks if the argument *a* is greater than or equals to the argument *b*.|
|le|lessequal|(*a*, *b*)|Checks if the argument *a* is less than or equals to the argument *b*.|
|ne|notequal|(*a*, *b*)|Checks if the argument *a* is not equal to the argument *b*. Case-sensitive.|
|ine||(*a*, *b*)|Checks if the argument *a* is not equal to the argument *b*. Case-insensitive.|
|match||(*a*, *b*)|Regular expression match. The second argument is treated as a regular expression. Case-sensitive.|
|imatch||(*a*, *b*)|Regular expression match. The second argument is treated as a regular expression. Case-insensitive.|
|interval||(*a*,*v<sub>1</sub>*,*t<sub>1</sub>*,...,*v<sub>n</sub>*,*t<sub>n</sub>*,*d*)|Finds the first *t<sub>i</sub>* that is greater than or equal to *a* and returns the corresponding *v<sub>i</sub>*. Returns *d* if all *t* are less than *a*.|
