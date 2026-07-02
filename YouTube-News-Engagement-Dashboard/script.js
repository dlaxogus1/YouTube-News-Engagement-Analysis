const button = document.getElementById("showDataBtn");
const dataArea = document.getElementById("dataArea");

const channelButton = document.getElementById("showChannelBtn");
const channelArea = document.getElementById("channelArea");

let isVisible = false;
let isChannelVisible = false;
let newsData = [];

button.addEventListener("click", function () {
  if (isVisible) {
    dataArea.innerHTML = "";
    isVisible = false;
    return;
  }

  Papa.parse("data/뉴스통합_50만이상.csv", {
    download: true,
    header: true,
    complete: function (result) {
      newsData = result.data.filter(row => row["title"]);
      makeTable(newsData);
      isVisible = true;
  }
});
});

channelButton.addEventListener("click", function () {
  if (isChannelVisible) {
    channelArea.innerHTML = "";
    isChannelVisible = false;
    return;
  }

  Papa.parse("data/뉴스통합_50만이상.csv", {
    download: true,
    header: true,
    complete: function (result) {
      makeChannelTable(result.data);
      isChannelVisible = true;
    }
  });
});

function makeTable(data) {
  let table = "<table>";

  table += `
    <tr>
      <th>채널</th>
      <th>제목</th>
      <th>조회수</th>
      <th>좋아요</th>
      <th>댓글</th>
    </tr>
  `;

  data.forEach(function (row) {
    table += `
      <tr>
        <td>${row["채널"]}</td>
        <td>${row["title"]}</td>
        <td>${row["views"]}</td>
        <td>${row["likes"]}</td>
        <td>${row["comments"]}</td>
      </tr>
    `;
  });

  table += "</table>";
  dataArea.innerHTML = table;
}

function makeChannelTable(data) {
  const counts = {
    SBS: 0,
    KBS: 0,
    MBC: 0,
    YTN: 0
  };

data.forEach(function (row) {
  const channel = row["채널"];

  if (channel.includes("SBS")) {
    counts.SBS++;
  } else if (channel.includes("KBS")) {
    counts.KBS++;
  } else if (channel.includes("MBC")) {
    counts.MBC++;
  } else if (channel.includes("YTN")) {
    counts.YTN++;
  }
});

channelArea.innerHTML = `
  <div class="channel-table-container">
    <table>
      <tr>
        <th>채널</th>
        <th>수집 영상 수</th>
      </tr>
      <tr>
        <td>SBS</td>
        <td>${counts.SBS}개</td>
      </tr>
      <tr>
        <td>KBS</td>
        <td>${counts.KBS}개</td>
      </tr>
      <tr>
        <td>MBC</td>
        <td>${counts.MBC}개</td>
      </tr>
      <tr>
        <td>YTN</td>
        <td>${counts.YTN}개</td>
      </tr>
    </table>
  </div>
`;
}

const searchInput = document.getElementById("searchInput");
const searchBtn = document.getElementById("searchBtn");
const resetBtn = document.getElementById("resetBtn");

searchBtn.addEventListener("click", function () {
  const keyword = searchInput.value.toLowerCase();

  const filteredData = newsData.filter(function (row) {
    return (
      row["채널"].toLowerCase().includes(keyword) ||
      row["title"].toLowerCase().includes(keyword)
    );
  });

  makeTable(filteredData);
});

resetBtn.addEventListener("click", function () {
  searchInput.value = "";
  makeTable(newsData);
});