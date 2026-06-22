import React from "react";
import Chart from "react-apexcharts";

const StudentChart = ({ totalSeats, enrolledStudents, color1, color2, labels }) => {
  const filledSeats = enrolledStudents;
  const vacantSeats = totalSeats - enrolledStudents;
  
  const chartOptions = {
    chart: { type: "pie" },
    stroke: { show: false }, 
    labels: labels,
    colors: [color1, color2],
    legend: { show: false },
    plotOptions: {
      pie: {
        expandOnClick: false, // Prevents the segments from expanding on click
        dataLabels: {
          offset: -10, // Moves the percentage labels slightly inward
        }
      }
    },
    dataLabels: {
      enabled: true,
      style: {
        fontSize: "12px",
        fontWeight: "bold",
      },
      formatter: (val) => Math.round(val) + "%", // Removes decimal points
      offset: -10, // Moves the text inside the chart
    },
    tooltip: {
      y: { formatter: (val) => Math.round(val) + "%" }, // Removes decimal points in tooltips
    },
  };

  const chartSeries = [filledSeats, vacantSeats];

  return <Chart options={chartOptions} series={chartSeries} type="pie" width="170" />;
};

export default StudentChart;
