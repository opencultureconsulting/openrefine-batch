# Example Powerhouse Museum

## Tutorial

Seth van Hooland, Ruben Verborgh and Max De Wilde (August 5, 2013): Cleaning Data with OpenRefine. In: The Programming Historian. http://programminghistorian.org/lessons/cleaning-data-with-openrefine

## Usage

```
./openrefine-batch.sh \
-a examples/powerhouse-museum/input/ \
-b examples/powerhouse-museum/config/ \
-c examples/powerhouse-museum/output/ \
-f tsv \
-i processQuotes=false \
-i guessCellValueTypes=true \
-RX
```

## input/phm-collection.tsv

* The [Powerhouse Museum in Sydney](https://maas.museum/powerhouse-museum/) provides a freely available metadata export of its collection on its website. The collection metadata has been retrieved from the website freeyourmetadata.org that has redistributed the data: http://data.freeyourmetadata.org/powerhouse-museum/

## config/phm-tutorial.json

* All steps from the tutorial above, extracted from the history of the processed tutorial project, retrieved from the website freeyourmetadata.org: [phm-collection-cleaned.google-refine.tar.gz](http://data.freeyourmetadata.org/powerhouse-museum/phm-collection-cleaned.google-refine.tar.gz)

## License

* The data is released under a [Creative Commons Attribution-ShareAlike 2.5 Australia License](http://creativecommons.org/licenses/by-nc/2.5/au/)
