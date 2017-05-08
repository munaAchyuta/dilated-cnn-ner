#!/bin/bash

conf=$1
if [ ! -e $conf ]; then
    echo "No config file specified; Exiting."
    exit 1
fi
source $conf

additional_args=${@:2}

output_dir="$SIMPLE_CNN_NER_ROOT/data/$data_name-w$filter_width-$embeddings_name"
vocab_param="--vocab $embeddings"
labels_param=""
char_param=""
shape_param=""

lower_param=""
if [[ "$lowercase" == "true" ]]; then
    lower_param="--lower"
fi

start_end_param=""
if [[ "$start_end" == "true" ]]; then
    start_end_param="--start_end"
    output_dir="$output_dir-start_end"
fi

predict_pad_param=""
if [[ "$predict_pad" == "true" ]]; then
    predict_pad_param="--predict_pad"
    output_dir="$output_dir-pred_pad"
fi

doc_param=""
if [[ "$documents" == "true" ]]; then
    doc_param="--documents"
    output_dir="$output_dir-docs"
fi

update_vocab_param=""
if [[ "$update_vocab_file" != "" ]]; then
    update_vocab_param="--update_vocab $update_vocab_file"
fi

echo "Writing output to $output_dir"

for (( i=0; i < ${#data_files[@]}; i++)); do

#for filename in "${data_files[@]}"; do
    filename=${data_files[$i]}

    update_maps="False"
    if [[ "$filename" =~ "train" ]]; then
        update_maps="True"
    fi
    if [ -d $raw_data_dir/$filename ]; then
        for this_data_file in `find $raw_data_dir/$filename -type d | tail -n +2`; do
            this_output_dir=$output_dir/$filename #/${this_data_file##*/}

#            if [[ "$update_maps" == "False" ]]; then
#                labels_param="--labels $this_output_dir/label.txt"
#                shape_param="--shapes $this_output_dir/shape.txt"
#                char_param="--chars $this_output_dir/char.txt"
#            fi

            echo "Processing file: $this_data_file"

            mkdir -p $this_output_dir/protos

            cmd="python $process_script \
            --in_file $this_data_file \
            --out_dir $this_output_dir \
            --window_size $filter_width \
            --update_maps $update_maps \
            $update_vocab_param \
            $lower_param \
            $vocab_param \
            $labels_param \
            $shape_param \
            $char_param \
            $doc_param \
            $predict_pad_param \
            $start_end_param \
            $additional_args"
            echo ${cmd}
            eval ${cmd}

    #        vocab_param="--vocab $this_output_dir/token.txt"
            labels_param="--labels $this_output_dir/label.txt"
            shape_param="--shapes $this_output_dir/shape.txt"
            char_param="--chars $this_output_dir/char.txt"
        done
    else
        this_data_file=$raw_data_dir/$filename
        this_output_dir=$output_dir/$filename

        echo "Processing file: $this_data_file"

        mkdir -p $this_output_dir

        cmd="python $process_script \
        --in_file $this_data_file \
        --out_dir $this_output_dir \
        --window_size $filter_width \
        --update_maps $update_maps \
        $update_vocab_param \
        $lower_param \
        $vocab_param \
        $labels_param \
        $shape_param \
        $char_param \
        $doc_param \
        $predict_pad_param \
        $start_end_param \
        $additional_args"
        echo ${cmd}
        eval ${cmd}

        if [[ "$filename" =~ "train" ]]; then
    #        vocab_param="--vocab $this_output_dir/token.txt"
            labels_param="--labels $this_output_dir/label.txt"
            shape_param="--shapes $this_output_dir/shape.txt"
            char_param="--chars $this_output_dir/char.txt"
        fi
    fi

done
