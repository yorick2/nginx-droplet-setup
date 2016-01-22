function test(){
    local i;     # make not usable outside function
    question=${1};
    #
    name=$2[@]; # name of the array
    allowedOptions=("${!name}"); # the array content
    #
    loop=true;
    while [ "$loop" == true ]; do 
      echo question;
      read varName;
      for i in "${allowedOptions[@]}"; do
          if [ "$i" == "$varName" ] ; then
              returned="$varName";
              loop=false;
          fi
      done
    done
}
allowed=('y' 'n');
test "my question" allowed ;
echo "returned = ";
echo $returned;
echo $i;