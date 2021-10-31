let table = document.getElementsByTagName("tbody")[1];
let lastCountry = null;
let csvFile;

for (var i = 0, row; row = table.rows[i]; i++) {
    if (row.cells.length <= 1) continue;

    let country = row.cells[1].getElementsByTagName("a")[0];

    if (!country || row.cells.length <= 2) {
        country = lastCountry;
    }

    csvFile += '(\'' + row.cells[0].innerText + '\',\'' + country.innerText + '\'),\n';
    lastCountry = country;
}

console.log("RESULT");
console.log(csvFile);