html:
	echo "<head><html><title> $MNAME </title>" > analysis.html
	echo "<script  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"  type="text/javascript"></script></head>" >>analysis.html
	#echo "<script type=\"text/javascript\" src=\"https://cdn.jsdelivr.net/npm/mathjax@2/MathJax.js?config=TeX-AMS_HTML\">  window.MathJax = {    tex2jax: {      inlineMath: [ [\'\$\',\'\$\'], [\"\$\$\",\"\$\$\"] ],      processEscapes: true    }  };</script>" >> analysis.html
	python3 -m mistletoe analysis.md >> analysis.html
	#-c config.json -x redcarpet,mdx_math analysis.md >> analysis.html
pdf:
	cat analysis.md|sed "s/\`\`\`solidity/.. code-block:: solidity/"|sed "s/\`\`\`//" > analysis.rst
	rst2pdf analysis.rst
