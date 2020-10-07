#include "defs.S"
#include "../../generic/data.S"
#include "../../generic/macros.S"
#include "../../generic/outerinterpreter.S"
#include "innerinterpreter.S"
#include "primitives.S"
#include "ext.S"
#include "../../generic/words.S"
#include "init.S"

.global _start

.text
_start: init_forth	
