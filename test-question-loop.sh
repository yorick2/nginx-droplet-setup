ask_question(){
    loop=true;
    varName="${1}"
    question="${2}";
   	shift;
   	shift;
    allowedOptions=("${@}");
    echo $allowedOptions;
    while [ "$loop" == true ]; do 
		echo $question;
		read $varName;
		for i in "${allowedOptions[@]}"; do
		    if [ "$i" == "$varName" ] ; then
		        echo "Found";
		    fi
		done
    done
}

echo 'askmy q';
array=('y' 'n');
ask_question test "hit key" ${array[@]} ;
echo $test ;


# a='y';
# array=('y' 'n');
# for i in "${array[@]}"; do
# 	#local i;
# 		    if [ "$i" == "$a" ] ; then
# 		        echo "Found";
# 		    fi
# 		done