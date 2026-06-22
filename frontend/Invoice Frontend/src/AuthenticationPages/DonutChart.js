// import React from "react";
// import Chart from "react-apexcharts";

// const DonutChart = ({ passCount, failCount }) => {
//   const total = passCount + failCount;
//   const passPercentage = Math.round((passCount / total) * 100);
//   const failPercentage = Math.round((failCount / total) * 100);

//   const chartOptions = {
//     chart: { type: "donut" },
//     stroke: { show: false }, 
//     labels: ["Pass", "Fail"],
//     colors: ["#4CAF50", "#E53935"], // Green & Red
//     legend: {
//         show: false, 
//       },
//     dataLabels: {
//       enabled: true,
//       formatter: (val) => Math.round(val) + "%", // Ensures no decimal points
//       style: { fontSize: "10px", fontWeight: "bold" },
//     },
//     tooltip: {
//       y: { formatter: (val) => Math.round(val) + "%" },
//     },
//   };

//   const chartSeries = [passPercentage, failPercentage];

//   return (
//       <Chart options={chartOptions} series={chartSeries} type="donut" width="170" />
//   );
// };

// export default DonutChart;
